//
//  CLTAppDelegate.m
//  CoolTerm
//
//  Created by Tom Lieber on 9/23/14.
//  Copyright (c) 2014 Tom Lieber. All rights reserved.
//

#import "CLTAppDelegate.h"
#import "CLTDocument.h"

@implementation CLTAppDelegate {
    BOOL isInBackground;
    NSMutableSet *windowsWithActivity;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(terminalActivity:)
                                                 name:CLTTerminalDocumentActivityNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(preferencesChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:[NSUserDefaults standardUserDefaults]];
}

- (void)preferencesChanged:(NSNotification *)notification {
    [self updateBadge];
}


#pragma mark - Dock Badge

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    isInBackground = NO;
    windowsWithActivity = nil;
    
    [self updateBadge];
}

- (void)applicationDidResignActive:(NSNotification *)notification {
    isInBackground = YES;
    windowsWithActivity = [NSMutableSet new];
}

- (void)terminalActivity:(NSNotification *)notification {
    [windowsWithActivity addObject:[NSValue valueWithPointer:(__bridge const void *)(notification.object)]];
    [self updateBadge];
}

- (void)updateBadge {
    if (!self.showActivityBadge || windowsWithActivity == nil || windowsWithActivity.count == 0) {
        [NSApplication sharedApplication].dockTile.badgeLabel = nil;
    } else {
        [NSApplication sharedApplication].dockTile.badgeLabel = @(windowsWithActivity.count).description;
    }
}


#pragma mark - Menu Actions

- (IBAction)showPreferences:(id)sender {
    [self updateFontPreferenceLabel];
    [self.preferencesWindow makeKeyAndOrderFront:nil];
}


#pragma mark - Preferences Window

- (IBAction)changeDefaultFont:(id)sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    [fontManager setSelectedFont:self.currentDefaultFont isMultiple:NO];
    
    NSFontPanel *fontPanel = [fontManager fontPanel:YES];
    [fontPanel makeKeyAndOrderFront:self.preferencesWindow];
}

- (IBAction)resetDefaultFont:(id)sender {
    self.currentDefaultFont = self.systemDefaultFont;
}

- (void)updateFontPreferenceLabel {
    NSFont *font = self.currentDefaultFont;
    self.defaultFontPreferenceLabel.stringValue = [NSString stringWithFormat:@"%@ %@ pt.", font.displayName, @(font.fontDescriptor.pointSize)];
}

// from font window, via responder chain
- (void)changeFont:(NSFontManager *)sender {
    self.currentDefaultFont = [sender convertFont:self.currentDefaultFont];
}

- (NSFont *)currentDefaultFont {
    NSFont *defaultFont = self.systemDefaultFont;
    
    NSNumber *fontSize = [[NSUserDefaults standardUserDefaults] objectForKey:@"Default Font Size"];
    NSDictionary *fontAttributes = [[NSUserDefaults standardUserDefaults] objectForKey:@"Default Font Attributes"];
    if (fontSize == nil || fontAttributes == nil) {
        return defaultFont;
    }
    
    NSFontDescriptor *fontDescriptor = [NSFontDescriptor fontDescriptorWithFontAttributes:fontAttributes];
    NSFont *font = [NSFont fontWithDescriptor:fontDescriptor size:fontSize.floatValue];
    if (font == nil) {
        return defaultFont;
    }
    
    return font;
}

- (void)setCurrentDefaultFont:(NSFont *)font {
    NSFontDescriptor *fontDescriptor = font.fontDescriptor;
    NSDictionary *fontAttributes = fontDescriptor.fontAttributes;
    NSNumber *fontSize = @(fontDescriptor.pointSize);
    
    [[NSUserDefaults standardUserDefaults] setObject:fontAttributes forKey:@"Default Font Attributes"];
    [[NSUserDefaults standardUserDefaults] setObject:fontSize forKey:@"Default Font Size"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self updateFontPreferenceLabel];
}

- (BOOL)showActivityBadge {
    NSNumber *activityBadge = [[NSUserDefaults standardUserDefaults] objectForKey:@"Activity Badge"];
    if (activityBadge == nil || ![activityBadge isKindOfClass:[NSNumber class]]) {
        return self.defaultShowActivityBadge;
    }
    
    return activityBadge.boolValue;
}

- (void)setShowActivityBadge:(BOOL)show {
    [[NSUserDefaults standardUserDefaults] setBool:show forKey:@"Activity Badge"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// preference defaults

- (NSFont *)systemDefaultFont {
    return [NSFont userFixedPitchFontOfSize:0];
}

- (BOOL)defaultShowActivityBadge {
    return YES;
}

@end
