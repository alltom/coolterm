//
//  CLTAppDelegate.m
//  CoolTerm
//
//  Created by Tom Lieber on 9/23/14.
//  Copyright (c) 2014 Tom Lieber. All rights reserved.
//

#import "CLTAppDelegate.h"

@implementation CLTAppDelegate

- (IBAction)showPreferences:(id)sender {
    [self updateFontPreferenceLabel];
    [self.preferencesWindow makeKeyAndOrderFront:nil];
}

- (IBAction)changeDefaultFont:(id)sender {
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    [fontManager setSelectedFont:self.currentDefaultFont isMultiple:NO];
    
    NSFontPanel *fontPanel = [fontManager fontPanel:YES];
    [fontPanel makeKeyAndOrderFront:self.preferencesWindow];
}

- (IBAction)resetDefaultFont:(id)sender {
    self.currentDefaultFont = self.systemDefaultFont;
}

- (void)changeFont:(NSFontManager *)sender {
    self.currentDefaultFont = [sender convertFont:self.currentDefaultFont];
}

- (NSFont *)systemDefaultFont {
    return [NSFont userFixedPitchFontOfSize:0];
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
    
    [self updateFontPreferenceLabel];
}

- (void)updateFontPreferenceLabel {
    NSFont *font = self.currentDefaultFont;
    self.defaultFontPreferenceLabel.stringValue = [NSString stringWithFormat:@"%@ %@ pt.", font.displayName, @(font.fontDescriptor.pointSize)];
}

@end
