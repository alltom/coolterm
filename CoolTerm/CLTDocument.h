//
//  CLTDocument.h
//  CoolTerm
//
//  Created by Tom Lieber on 1/18/14.
//  Copyright (c) 2014 Tom Lieber. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *CLTTerminalDocumentActivityNotification;

@class CLTTerminal;

@interface CLTDocument : NSDocument

@property (unsafe_unretained) IBOutlet CLTTerminal *terminal;

@end
