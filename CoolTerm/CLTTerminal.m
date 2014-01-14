//
//  CLTTerminal.m
//  CoolTerm
//
//  Created by Tom Lieber on 1/12/14.
//  Copyright (c) 2014 Tom Lieber. All rights reserved.
//

#import "CLTTerminal.h"

@implementation CLTTerminal
{
    NSScrollView *scrollView;
    
    NSTask *task;
    NSPipe *inputPipe;
    NSPipe *outputPipe;
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

- (NSString *)pendingInput
{
    return [[self.textStorage string] substringFromIndex:nonInputLength];
}

- (void)receivedData:(NSData *)data
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:string attributes:nil];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        for (int i = 0; i < byteRange.length; i++) {
            const unsigned char *chars = (const unsigned char *)bytes;
            if (chars[i] < 32 && chars[i] != 10 && chars[i] != 13 && chars[i] != 9) {
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

- (BOOL)isEndOfTextVisible
{
    NSRange glyphRange = [self.layoutManager glyphRangeForBoundingRect:scrollView.documentVisibleRect
                                                       inTextContainer:self.textContainer];
    return self.textStorage.string.length == glyphRange.location + glyphRange.length;
}

- (void)start
{
    self.automaticDashSubstitutionEnabled = NO;
    self.automaticQuoteSubstitutionEnabled = NO;
    
    scrollView = (NSScrollView *)self.superview.superview;
    scrollView.contentView.postsBoundsChangedNotifications = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrolled:)
                                                 name:NSViewBoundsDidChangeNotification
                                               object:scrollView.contentView];
    
    task = [NSTask new];
    task.launchPath = @"/bin/bash";
    task.arguments = @[@"-i", @"-l", @"-s"];
    task.environment = @{ @"TERM" : @"dumb" };
    
    task.standardInput = inputPipe = [NSPipe pipe];
    task.standardOutput = outputPipe = [NSPipe pipe];
    task.standardError = errorOutputPipe = [NSPipe pipe];
    
    __block typeof(self) weakSelf = self;
    readHandler = ^(NSFileHandle *handle) {
        NSData *data = handle.availableData;
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) strongSelf = weakSelf;
            [strongSelf receivedData:data];
        });
    };
    
    [self enableReads:YES];
    
    [task launch];
}

- (void)enableReadsIfNecessary
{
    [self enableReads:self.isEndOfTextVisible];
}

- (void)enableReads:(BOOL)enable
{
    if (enable && !readsEnabled) {
        outputPipe.fileHandleForReading.readabilityHandler = readHandler;
        errorOutputPipe.fileHandleForReading.readabilityHandler = readHandler;
        readsEnabled = YES;
    } else if (!enable && readsEnabled) {
        outputPipe.fileHandleForReading.readabilityHandler = nil;
        errorOutputPipe.fileHandleForReading.readabilityHandler = nil;
        readsEnabled = NO;
    }
}

- (void)scrolled:(id)sender
{
    [self enableReadsIfNecessary];
}

- (IBAction)sendCommand:(id)sender
{
    [self writeCommand:[self.textStorage.string substringWithRange:self.selectedRange]];
}

- (void)writeCommand:(NSString *)command
{
    if (![command hasSuffix:@"\n"]) {
        command = [command stringByAppendingString:@"\n"];
    }
    [inputPipe.fileHandleForWriting writeData:[command dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
