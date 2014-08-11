//
//  CLTDocument.m
//  CoolTerm
//
//  Created by Tom Lieber on 1/18/14.
//  Copyright (c) 2014 Tom Lieber. All rights reserved.
//

#import "CLTDocument.h"
#import "CLTTerminal.h"

@implementation CLTDocument
{
    NSString *path;
    NSAttributedString *history;
}

- (NSString *)windowNibName
{
    return @"CLTDocument";
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (void)dealloc
{
    [self.terminal cleanUp];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
    if (history) {
        // XXX: for some reason, doing this synchronously leaves the cursor in the wrong position
        [self.terminal performSelector:@selector(addHistory:) withObject:history afterDelay:0.3];
        history = nil;
    }
    
    if (path) {
        self.terminal.currentDirectoryPath = path;
        path = nil;
    }
    
    self.terminal.terminationHandler = ^(CLTTerminal *terminal){
        [self close];
    };
    [self.terminal startShell];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    [self.terminal breakUndoCoalescing];
    NSAttributedString *text = self.terminal.attributedString;
    NSData *textData = [text dataFromRange:NSMakeRange(0, text.length)
                        documentAttributes:@{NSDocumentTypeDocumentAttribute : NSRTFDTextDocumentType}
                                     error:outError];
    
    if (textData == nil) {
        return nil;
    }
    
    NSDictionary *currentState = @{@"Text" : textData,
                                   @"Path" : self.terminal.currentDirectoryPath};
    
    return [NSKeyedArchiver archivedDataWithRootObject:currentState];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    NSDictionary *currentState = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (![currentState isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    
    path = currentState[@"Path"];
    if (![path isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    NSData *textData = currentState[@"Text"];
    if (![textData isKindOfClass:[NSData class]]) {
        return NO;
    }
    
    history = [[NSAttributedString alloc] initWithData:textData
                                               options:nil
                                    documentAttributes:nil
                                                 error:outError];
    if (history == nil) {
        return NO;
    }
    
    return YES;
}

// don't show a save dialog when a window is closed
// override this to just tell the delegate to close instead of showing a dialog and saving first
- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
{
    NSMethodSignature *ms;
    NSInvocation *inv;
    BOOL shouldClose = YES;
    
    if ([delegate respondsToSelector:shouldCloseSelector]) {
        ms = [delegate methodSignatureForSelector:shouldCloseSelector];
        inv = [NSInvocation invocationWithMethodSignature:ms];
        
        [inv setTarget:delegate];
        [inv setSelector:shouldCloseSelector];
        [inv setArgument:&delegate atIndex:2];
        [inv setArgument:&shouldClose atIndex:3];
        [inv setArgument:&contextInfo atIndex:4];
        
        [inv invoke];
    }
}

@end
