//
//  CLTAppDelegate.h
//  CoolTerm
//
//  Created by Tom Lieber on 9/23/14.
//  Copyright (c) 2014 Tom Lieber. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CLTAppDelegate : NSObject <NSApplicationDelegate>

// Preferences

@property (weak) IBOutlet NSWindow *preferencesWindow;
@property (weak) IBOutlet NSTextField *defaultFontPreferenceLabel;

- (NSFont *)currentDefaultFont;

@end
