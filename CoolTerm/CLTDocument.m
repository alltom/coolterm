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

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
    if (history) {
        [self.terminal addHistory:history];
        history = nil;
    }
    
    if (path) {
        self.terminal.currentDirectoryPath = path;
        path = nil;
    }
    
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

@end
