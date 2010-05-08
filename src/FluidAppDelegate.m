//  Copyright 2009 Todd Ditchendorf
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "FluidAppDelegate.h"
#import "FluidWindowController.h"
#import "FluidPreferencesWindowController.h"
#import <WebKit/WebKit.h>

NSString *const kFluidDestinationDirKey = @"FluidDestinationDir";

@interface WebIconDatabase
+ (id)sharedIconDatabase;
@end
    
@interface FluidAppDelegate (Private)
+ (void)setupDefaults;
+ (NSString *)createIconDatabaseDirAndReturnPath;

- (void)registerForAppleEventHandling;
- (void)handleOpenContentsAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent;
@end

@implementation FluidAppDelegate

+ (void)initialize {
    if ([FluidAppDelegate class] == self) {
        // necessary hack to initialize icon db. if you don't, favicons will not be reported.
        [WebIconDatabase sharedIconDatabase];

        [self setupDefaults];
    }
}


+ (void)setupDefaults {
    NSString *destDir = [NSString pathWithComponents:[NSArray arrayWithObjects:@"/", @"Applications", nil]];
    
    NSMutableDictionary *defaults = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     destDir, kFluidDestinationDirKey,
                                     nil];
    
    NSString *iconDirPath = [self createIconDatabaseDirAndReturnPath];
    if ([iconDirPath length]) {
        [defaults setObject:iconDirPath forKey:@"WebIconDatabaseDirectoryDefaultsKey"];
    }
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaults];
}


+ (NSString *)createIconDatabaseDirAndReturnPath {
    NSArray *pathComps = [NSArray arrayWithObjects:@"~", @"Library", @"Application Support", @"Fluid", @"IconDatabase", nil];
    NSString *path = [[NSString pathWithComponents:pathComps] stringByExpandingTildeInPath];
    
    BOOL exists, isDir;
    exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    exists = (exists && isDir);
    
    if (!exists) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil]) {
            NSLog(@"Fluid could not create icon database dir at path: %@!", path);
        }
    }
        
    return path;
}


- (id)init {
    if (self = [super init]) {
        [self registerForAppleEventHandling];
    }
    return self;
}


- (void)dealloc {
    [[NSAppleEventManager sharedAppleEventManager] removeEventHandlerForEventClass:kInternetEventClass andEventID:kAEGetURL]; 

    self.windowController = nil;
    self.preferencesWindowController = nil;
    [super dealloc];
}


- (void)awakeFromNib {

}


#pragma mark - 
#pragma mark Actions

- (IBAction)showMainWindow:(id)sender {
    [self.windowController showWindow:sender];
}


- (IBAction)showPreferencesWindow:(id)sender {
    [self.preferencesWindowController showWindow:sender];
}


- (IBAction)setLocationTo:(id)sender {
    [self.windowController setLocationTo:sender];
}


- (void)installPlugInAtPath:(NSString *)path {
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    NSArray *comps = [NSArray arrayWithObjects:@"~", @"Library", @"Application Support", @"Fluid", @"PlugIns", nil];
    NSString *plugInDirPath = [[NSString pathWithComponents:comps] stringByExpandingTildeInPath];
    
    NSError *err = nil;
    NSString *title, *msgFormat, *defaultButton = NSLocalizedString(@"OK", @"");

    if (![mgr createDirectoryAtPath:plugInDirPath withIntermediateDirectories:YES attributes:nil error:&err]) {
        NSLog(@"%@", [err description]);
        title = NSLocalizedString(@"Error Installing Plug-in", @"");
        msgFormat = [NSString stringWithFormat:NSLocalizedString(@"Could not create Fluid Plug-in directory. You will need write permissions for this directory: \n\n %@", @""), plugInDirPath];
        NSRunAlertPanel(title, msgFormat, defaultButton, nil, nil);
        return;
    }

    NSString *destPath = [plugInDirPath stringByAppendingPathComponent:[path lastPathComponent]];
    err = nil;

    if ([mgr moveItemAtPath:path toPath:destPath error:&err]) {
        title = NSLocalizedString(@"Plug-in Successfully Installed", @"");
        msgFormat = [NSString stringWithFormat:NSLocalizedString(@"This Fluid Plug-in has been installed for all Fluid-created Site Specific Browsers.\n\nYou will need to restart any SSB to use the Plug-in.", @"")];
        NSRunInformationalAlertPanel(title, msgFormat, defaultButton, nil, nil);
    } else {
        NSLog(@"%@", [err description]);
        title = NSLocalizedString(@"Error Installing Plug-in", @"");
        msgFormat = [NSString stringWithFormat:NSLocalizedString(@"Could not move Plug-in file to the Fluid Plug-in directory. You will need write permissions for this directory: \n\n %@", @""), plugInDirPath];
        NSRunAlertPanel(title, msgFormat, defaultButton, nil, nil);
    }
}


#pragma mark - 
#pragma mark AppleEventHandling

- (void)registerForAppleEventHandling {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleOpenContentsAppleEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];    
}


- (void)handleOpenContentsAppleEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    self.windowController.appURLString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
}


#pragma mark -
#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)n {
    [self showMainWindow:self];
}


- (BOOL)application:(NSApplication *)app openFile:(NSString *)filename {
    if ([[filename lastPathComponent] hasSuffix:@"fluidplugin"]) {
        [self installPlugInAtPath:filename];        
    }
    return YES;
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app {
    return YES;
}


#pragma mark -
#pragma mark Properties

- (FluidWindowController *)windowController {
    if (!windowController) {
        self.windowController = [[[FluidWindowController alloc] init] autorelease];
    }
    return windowController;
}


- (FluidPreferencesWindowController *)preferencesWindowController {
    if (!preferencesWindowController) {
        self.preferencesWindowController = [[[FluidPreferencesWindowController alloc] init] autorelease];
    }
    return preferencesWindowController;
}

@synthesize windowController;
@synthesize preferencesWindowController;
@end
