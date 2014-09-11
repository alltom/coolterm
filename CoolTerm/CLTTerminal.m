//
//  CLTTerminal.m
//  CoolTerm
//
//  Created by Tom Lieber on 1/12/14.
//  Copyright (c) 2014 Tom Lieber. All rights reserved.
//

#include <util.h>
#import "CLTTerminal.h"

@interface CLTTerminal () <NSTextViewDelegate>
@end

@implementation CLTTerminal
{
    NSScrollView *scrollView;
    
    NSTask *task;
    NSFileHandle *masterHandle;
    NSPipe *errorOutputPipe;
    NSUInteger nonInputLength;
    
    void (^readHandler)(NSFileHandle *);
    BOOL readsEnabled;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self start];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self start];
}

- (void)setFrame:(NSRect)frameRect
{
    frameRect.size.height += scrollView.frame.size.height - 20;
    [super setFrame:frameRect];
}

- (void)setFrameSize:(NSSize)newSize
{
    newSize.height += scrollView.frame.size.height - 20;
    [super setFrameSize:newSize];
}

- (void)cleanUp
{
    [masterHandle closeFile];
    [task terminate];
}

- (void)start
{
    self.delegate = self;
    
    self.automaticDashSubstitutionEnabled = NO;
    self.automaticQuoteSubstitutionEnabled = NO;
    
    scrollView = (NSScrollView *)self.superview.superview;
    scrollView.contentView.postsBoundsChangedNotifications = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrolled:)
                                                 name:NSViewBoundsDidChangeNotification
                                               object:scrollView.contentView];
    
    task = [NSTask new];
    
    NSDictionary *environment = [NSProcessInfo processInfo].environment;
    NSString *homePath = environment[@"HOME"];
    if (homePath) {
        task.currentDirectoryPath = homePath;
    }
}

- (IBAction)sendCommand:(id)sender
{
    [self writeCommand:[self.textStorage.string substringWithRange:self.selectedRange]];
}

- (NSString *)currentDirectoryPath
{
    return task.currentDirectoryPath;
}

- (void)setCurrentDirectoryPath:(NSString *)path
{
    task.currentDirectoryPath = path;
}

- (void)addHistory:(NSAttributedString *)history
{
    NSMutableAttributedString *as = [NSMutableAttributedString new];
    [as appendAttributedString:history];
    [as appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n--- end restored state ---\n"]];
    
    [self.textStorage insertAttributedString:as atIndex:0];
    nonInputLength += as.length;
}


#pragma mark - Text View Events

- (void)keyDown:(NSEvent *)theEvent
{
    NSUInteger flags = theEvent.modifierFlags;
    unsigned short keyCode = theEvent.keyCode;
    
    if ((flags & NSControlKeyMask) && keyCode == 8) {
        [masterHandle writeData:[NSData dataWithBytes:"\003" length:1]];
    } else if ((flags & NSControlKeyMask) && keyCode == 2) {
        [masterHandle writeData:[NSData dataWithBytes:"\004" length:1]];
    } else if ((flags & NSDeviceIndependentModifierFlagsMask) == 0 && keyCode == 126) {
        NSLog(@"up");
    } else if ((flags & NSDeviceIndependentModifierFlagsMask) == 0 && keyCode == 125) {
        NSLog(@"down");
    } else {
        [super keyDown:theEvent];
    }
}

- (BOOL)shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    BOOL should = [super shouldChangeTextInRange:affectedCharRange replacementString:replacementString];
    
    if (should && replacementString != nil) {
        if (affectedCharRange.location < nonInputLength) {
            if (replacementString.length > affectedCharRange.length) { // "" -> "asdf"
                nonInputLength += replacementString.length - affectedCharRange.length;
            } else { // "asdf" -> ""
                nonInputLength -= affectedCharRange.length - replacementString.length;
            }
        }
    }
    
    return should;
}

- (void)didChangeText
{
    NSString *input = self.pendingInput;
    if ([input hasSuffix:@"\n"]) {
        [self.textStorage replaceCharactersInRange:NSMakeRange(nonInputLength, input.length) withString:@""];
        [self writeCommand:input];
    }
}

- (void)scrolled:(id)sender
{
    [self enableReadsIfNecessary];
}


#pragma mark - Text View Helpers

- (NSString *)pendingInput
{
    return [[self.textStorage string] substringFromIndex:nonInputLength];
}

- (BOOL)isEndOfTextVisible
{
    NSRange glyphRange = [self.layoutManager glyphRangeForBoundingRect:scrollView.documentVisibleRect
                                                       inTextContainer:self.textContainer];
    return self.textStorage.string.length == glyphRange.location + glyphRange.length;
}


#pragma mark - I/O Helpers

- (void)startShell
{
    int amaster = 0, aslave = 0;
    if (openpty(&amaster, &aslave, NULL, NULL, NULL) == -1) {
        NSLog(@"openpty failed");
        return;
    }
    
    masterHandle = [[NSFileHandle alloc] initWithFileDescriptor:amaster closeOnDealloc:YES];
    NSFileHandle *slaveHandle = [[NSFileHandle alloc] initWithFileDescriptor:aslave closeOnDealloc:YES];
    
    NSMutableDictionary *environment = [NSProcessInfo processInfo].environment.mutableCopy;
    environment[@"TERM"] = @"dumb";
    
    task.launchPath = @"/bin/bash";
    task.arguments = @[@"-i", @"-l"];
    task.environment = environment;
    
    task.standardInput = slaveHandle;
    task.standardOutput = slaveHandle;
    task.standardError = errorOutputPipe = [NSPipe pipe];
    
    __block typeof(self) weakSelf = self;
    
    readHandler = ^(NSFileHandle *handle) {
        NSData *data = handle.availableData;
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) strongSelf = weakSelf;
            [strongSelf receivedData:data];
        });
    };
    
    task.terminationHandler = ^(NSTask *task){
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) strongSelf = weakSelf;
            if (strongSelf.terminationHandler != nil) {
                strongSelf.terminationHandler(strongSelf);
            }
        });
    };
    
    [self enableReads:YES];
    
    [task launch];
}

- (void)receivedData:(NSData *)data
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    string = [string stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:string attributes:nil];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        for (int i = 0; i < byteRange.length; i++) {
            const unsigned char *chars = (const unsigned char *)bytes;
            if (iscntrl(chars[i]) && chars[i] != 9 && chars[i] != 10 && chars[i] != 13) {
                NSLog(@"control character: %d", chars[i]);
            }
        }
    }];
    
    [self.textStorage insertAttributedString:as atIndex:nonInputLength];
    nonInputLength += as.length;
    
    if (!self.isEndOfTextVisible) {
        [self enableReads:NO];
    }
}

- (void)enableReads:(BOOL)enable
{
    if (enable && !readsEnabled) {
        masterHandle.readabilityHandler = readHandler;
        errorOutputPipe.fileHandleForReading.readabilityHandler = readHandler;
        readsEnabled = YES;
    } else if (!enable && readsEnabled) {
        masterHandle.readabilityHandler = nil;
        errorOutputPipe.fileHandleForReading.readabilityHandler = nil;
        readsEnabled = NO;
    }
}

- (void)enableReadsIfNecessary
{
    [self enableReads:self.isEndOfTextVisible];
}

- (void)writeCommand:(NSString *)command
{
    if (![command hasSuffix:@"\n"]) {
        command = [command stringByAppendingString:@"\n"];
    }
    [masterHandle writeData:[command dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
