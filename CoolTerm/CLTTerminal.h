//
//  CLTTerminal.h
//  CoolTerm
//
//  Created by Tom Lieber on 1/12/14.
//  Copyright (c) 2014 Tom Lieber. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CLTTerminal : NSTextView

- (void)cleanUp;
- (IBAction)sendCommand:(id)sender;
- (void)writeCommand:(NSString *)command;

- (NSString *)currentDirectoryPath;
- (void)setCurrentDirectoryPath:(NSString *)path;
- (void)addHistory:(NSAttributedString *)history;

- (void)startShell;

- (IBAction)toggleAutoScroll:(id)sender;

@property (nonatomic, copy) void (^terminationHandler)(CLTTerminal *terminal);

@property (nonatomic, assign) BOOL autoScroll;
@property (nonatomic, assign) NSUInteger scrollbackCharacters;

@end

@interface CLTTerminalScrollView : NSScrollView
@end
