//
//  CLTTerminal.h
//  CoolTerm
//
//  Created by Tom Lieber on 1/12/14.
//  Copyright (c) 2014 Tom Lieber. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CLTTerminal : NSTextView

- (IBAction)sendCommand:(id)sender;
- (void)writeCommand:(NSString *)command;

@end
