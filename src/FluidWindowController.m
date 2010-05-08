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

#import "FluidWindowController.h"
#import "FluidAppDelegate.h"
#import "FluidWhitelistProvider.h"
#import "NSString+FUAdditions.h"
#import "IconFamily.h"
#import <WebKit/WebKit.h>

#define TAG_SELECT_OTHER_APP_PATH 47

#define INDEX_SELECTED_CUSTOM_ICON_ITEM 2

#define TAG_APPLICATONS_DIR 0
#define TAG_HOME_DIR 1
#define TAG_DESKTOP_DIR 2

#define BUTTON_OK -1
#define BUTTON_REVEAL 0
#define BUTTON_LAUNCH_NOW 1

@interface WebIconDatabase
+ (id)sharedIconDatabase;
@end

@interface FluidWindowController ()
- (BOOL)canCreateAppWithNameAndLocation;
- (void)createLocalCustomIcon;
- (void)fetchDefaultTouchIcon;
- (void)loadAppHomePage;
- (void)checkForDoneFetching;
- (void)doneFetching;
- (void)createApp;
- (void)setUpDefaultValuesPlist;
- (NSArray *)patternDictsForAllURLStrings;
- (void)setUpInfoPlist;
- (void)setUpIcon;
- (BOOL)iconIsBiggerThanFavicon:(NSImage *)img;
- (void)touchApp;
- (void)handleSuccess;

- (void)launchApp:(NSString *)path;
- (void)handleError:(NSString *)localizedDescription;
- (void)playSuccessSound;

- (NSString *)stringWithSchemeAndTLD:(NSString *)inURLString;

- (void)appPathPopUpButtonMenuNeedsUpdate:(NSMenu *)menu;
- (void)openPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(NSInteger)code contextInfo:(id)sender;
- (void)appIconPathPopUpButtonMenuNeedsUpdate:(NSMenu *)menu;

- (void)handleDroppedFilenames:(NSArray *)filenames;
@end

@implementation FluidWindowController

- (id)init {
    return [self initWithWindowNibName:@"FluidWindow"];
}


- (id)initWithWindowNibName:(NSString *)name {
    if (self = [super initWithWindowNibName:name]) {
        self.appDestDir = [[NSUserDefaults standardUserDefaults] stringForKey:kFluidDestinationDirKey];
    }
    return self;
}


- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    self.appURLTextField = nil;
    self.appPathPopUpButton = nil;
    self.appPathPopUpButtonMenu = nil;
    self.appIconPathPopUpButton = nil;
    self.appIconPathPopUpButtonMenu = nil;
    self.webPageLoader = nil;
    self.appURLString = nil;
    self.appBundleIdentifier = nil;
    self.appName = nil;
    self.appDestDir = nil;
    self.appDestPath = nil;
    self.appCustomIconPath = nil;
    self.appIcon = nil;
    self.appLocalCustonIcon = nil;
    self.appDefaultTouchIcon = nil;
    self.appPreferredTouchIcon = nil;
    self.appFavicon = nil;
    self.appAllURLStrings = nil;
    self.allowedIconFileExtensions = nil;
    self.allowedIconImageExtensions = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    [[self window] center];
    
    [self menuNeedsUpdate:appPathPopUpButtonMenu];
    [self menuNeedsUpdate:appIconPathPopUpButtonMenu];
    
    [[self window] registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
}


#pragma mark - 
#pragma mark Actions

- (IBAction)run:(id)sender {
    self.doneCreatingLocalCustomIcon = NO;
    self.doneFetchingDefaultTouchIcon = NO;
    self.doneLoadingHomePage = NO;
    
    if (![appURLString length] || ![appName length] || ![appDestDir length]) {
        NSBeep();
        return;
    }
    
    if (![self canCreateAppWithNameAndLocation]) {
        return;
    }
    
    self.busy = YES;
    
    [[NSUserDefaults standardUserDefaults] setObject:appDestDir forKey:kFluidDestinationDirKey];
    
    SEL sel = NULL;
    if ([appCustomIconPath length]) {
        self.doneFetchingDefaultTouchIcon = YES;
        sel = @selector(createLocalCustomIcon);
    } else {
        self.doneCreatingLocalCustomIcon = YES;
        sel = @selector(fetchDefaultTouchIcon);
    }
    [NSThread detachNewThreadSelector:sel toTarget:self withObject:nil];
    [self loadAppHomePage];
}


- (IBAction)setLocationTo:(id)sender {
    switch ([sender tag]) {
        case TAG_APPLICATONS_DIR:
            self.appDestDir = [NSString pathWithComponents:[NSArray arrayWithObjects:@"/", @"Applications", nil]];
            break;
        case TAG_HOME_DIR:
            self.appDestDir = [[NSString pathWithComponents:[NSArray arrayWithObjects:@"~", nil]] stringByExpandingTildeInPath];
            break;
        case TAG_DESKTOP_DIR:
            self.appDestDir = [[NSString pathWithComponents:[NSArray arrayWithObjects:@"~", @"Desktop", nil]] stringByExpandingTildeInPath];
            break;
        default:
            break;
    }
    [self menuNeedsUpdate:appPathPopUpButtonMenu];
}


#pragma mark - 
#pragma mark Private

- (BOOL)canCreateAppWithNameAndLocation {
    // don't allow creation of SSBs with common apple app names in Applications folder    
    if (![appDestDir isEqualToString:@"/Applications"]) {
        return YES;
    }
    
    NSString *name = [appName lowercaseString];
    NSArray *names = [NSArray arrayWithObjects:@"applescript", @"calculator", @"chess", @"dashboard", @"dictionary", @"fluid", @"font book", 
                      @"front row", @"ical", @"ichat", @"idvd", @"imovie", @"image capture", @"iphoto", @"isync", @"itunes", @"iweb", @"mail",
                      @"photo booth", @"quicktime player", @"safari", @"spaces", @"system preferences", @"textedit", @"textmate", @"transmit", @"utilities", nil];
    
    for (NSString *currName in names) {
        if ([currName isEqualToString:name]) {
            NSBeep();
            NSRunAlertPanel(NSLocalizedString(@"App Name not allowed in /Applications", @""),
                            NSLocalizedString(@"Cannot create a Fluid App with the name %@ in the Applications folder as it is likely to conflict with the name of a common Mac OS X Application.\n\nIf you wish, you may create a Fluid App with this name in another folder and then manually move it to the Applications folder.", @""), 
                            NSLocalizedString(@"OK", @""),
                            nil,
                            nil,
                            appName);
            return NO;
        }
    } 

    return YES;
}


- (void)createLocalCustomIcon {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if ([self.allowedIconImageExtensions containsObject:[appCustomIconPath pathExtension]]) {
        self.appLocalCustonIcon = [[[NSImage alloc] initWithContentsOfFile:[appCustomIconPath stringByExpandingTildeInPath]] autorelease];
        
        if (!appLocalCustonIcon) {
            [self handleError:[NSString stringWithFormat:NSLocalizedString(@"Could not create Icon with file at path :\n%@", @""), appCustomIconPath]];
        }
    }
    
    self.doneCreatingLocalCustomIcon = YES;
    [self checkForDoneFetching];
    
    [pool release];
}


- (void)fetchDefaultTouchIcon {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *URLString = [self stringWithSchemeAndTLD:self.appURLString];
    
    NSURL *URL = [NSURL URLWithString:URLString];
    URLString = [NSString stringWithFormat:@"%@://%@%@", [URL scheme], [URL host], @"/apple-touch-icon.png"];
    URL = [NSURL URLWithString:URLString];

    self.appDefaultTouchIcon = [[[NSImage alloc] initWithContentsOfURL:URL] autorelease];
    
    self.doneFetchingDefaultTouchIcon = YES;
    [self checkForDoneFetching];
    
    [pool release];
}


- (void)loadAppHomePage {
    NSString *URLString = [self stringWithSchemeAndTLD:self.appURLString];
    [self.webPageLoader loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:URLString]]];
}


- (void)checkForDoneFetching {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(checkForDoneFetching) withObject:nil waitUntilDone:NO];
        return;
    }
    
    @synchronized (self) {
        if (self.doneLoadingHomePage && self.doneFetchingDefaultTouchIcon && self.doneCreatingLocalCustomIcon) {
            self.doneLoadingHomePage = NO;
            self.doneFetchingDefaultTouchIcon = NO;
            self.doneCreatingLocalCustomIcon = NO;
            [self performSelector:@selector(doneFetching) withObject:nil afterDelay:0];
        }
    }
}


- (void)doneFetching {
    [NSThread detachNewThreadSelector:@selector(createApp) toTarget:self withObject:nil];
}


- (void)createApp {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *srcPath = [[NSBundle mainBundle] pathForResource:@"Fluidium" ofType:@"app"];
    
    NSArray *appDestPathComponents = [NSArray arrayWithObjects:appDestDir, appName, nil];
    self.appDestPath = [[[NSString pathWithComponents:appDestPathComponents] stringByAppendingPathExtension:@"app"] stringByExpandingTildeInPath];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:appDestPath]) {
        NSString *title = NSLocalizedString(@"Overwrite Existing Application?", @"");
        NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"An application named %@ already exists at that location. Do you want to overwrite it?", @""), appName];
        NSString *defaultButton = NSLocalizedString(@"Overwrite", @"");
        NSString *alternateButton = NSLocalizedString(@"Cancel", @"");
        
        NSInteger button = NSRunAlertPanel(title, msg, defaultButton, alternateButton, nil);
        
        if (NSOKButton == button) {
            NSError *err = nil;
            if (![[NSFileManager defaultManager] removeItemAtPath:appDestPath error:&err]) {
                [self handleError:[err localizedDescription]];
                return;
            }
        } else {
            self.busy = NO;
            return;
        }
    }
    
    NSError *err = nil;
    if (![[NSFileManager defaultManager] copyItemAtPath:srcPath toPath:appDestPath error:&err]) {
        [self handleError:[err localizedDescription]];
        return;
    }
    
    [self setUpDefaultValuesPlist];
    [self setUpInfoPlist];    
    [self setUpIcon];
    [self touchApp];
    [self handleSuccess];
    
    [pool release];
}


- (void)touchApp {
    NSFileManager *mgr = [NSFileManager defaultManager];
    NSDictionary *attrs = [NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate];
    [mgr changeFileAttributes:attrs atPath:appDestPath];
}


- (void)setUpDefaultValuesPlist {
    NSArray *plistPathComponents = [NSArray arrayWithObjects:appDestPath, @"Contents", @"Resources", @"DefaultValues", nil];
    NSString *plistPath = [[NSString pathWithComponents:plistPathComponents] stringByAppendingPathExtension:@"plist"];
    
    NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    [plist setObject:appURLString forKey:@"FUHomeURLString"];
    [plist setObject:[NSNumber numberWithInteger:1] forKey:@"FUNewWindowsOpenWith"]; // home page
    [plist setObject:[NSNumber numberWithBool:NO] forKey:@"FUToolbarShown"];
    
    NSArray *patternDicts = [self patternDictsForAllURLStrings];
    if ([patternDicts count]) {
        [plist setObject:patternDicts forKey:@"FUWhitelistURLPatternStrings"];
        [plist setObject:[NSNumber numberWithBool:NO] forKey:@"FUAllowBrowsingToAnyDomain"];
    }
    
    // window frame
    NSRect screenFrame = [[[self window] screen] frame];
    CGFloat w = floor(screenFrame.size.width * .66);
    CGFloat h = floor(screenFrame.size.height * .66);
    NSRect winFrame = NSMakeRect(floor(screenFrame.size.width / 2 - w / 2), floor(screenFrame.size.height / 2 - h / 2), w, h);
    [plist setObject:NSStringFromRect(winFrame) forKey:@"FUWindowFrameString"];
    
    [plist writeToFile:plistPath atomically:YES];
}


- (NSArray *)patternDictsForAllURLStrings {
    NSMutableArray *a = [NSMutableArray arrayWithObject:appURLString];
    [a addObjectsFromArray:appAllURLStrings];
    return [FluidWhitelistProvider patternDictsForURLStrings:a];
}


- (void)setUpInfoPlist {
    NSArray *infoPlistPathComponents = [NSArray arrayWithObjects:appDestPath, @"Contents", @"Info", nil];
    
    NSString *infoPlistPath = [[NSString pathWithComponents:infoPlistPathComponents] stringByAppendingPathExtension:@"plist"];
    
    NSMutableDictionary *infoPlist = [NSMutableDictionary dictionaryWithContentsOfFile:infoPlistPath];
    
    self.appBundleIdentifier = [NSString stringWithFormat:@"%@.%@", [infoPlist objectForKey:@"CFBundleIdentifier"], appName];
    [infoPlist setObject:appBundleIdentifier forKey:@"CFBundleIdentifier"];
    [infoPlist setObject:appName forKey:@"CFBundleName"];
    [infoPlist setObject:appName forKey:@"FUAppName"];
    
    [infoPlist writeToFile:infoPlistPath atomically:YES];
}


- (void)setUpIcon {
    IconFamily *ifam = nil;
    
    if (appLocalCustonIcon) {
        self.appIcon = appLocalCustonIcon;
    } else if ([appCustomIconPath length]) {
        if ([[appCustomIconPath pathExtension] isEqualToString:@"icns"]) {
            ifam = [IconFamily iconFamilyWithContentsOfFile:[appCustomIconPath stringByExpandingTildeInPath]];
            self.appIcon = [ifam imageWithAllReps];
        } else {
            self.appIcon = [[NSWorkspace sharedWorkspace] iconForFile:[appCustomIconPath stringByExpandingTildeInPath]];
        }
    } 

    if (!appIcon) {
        if (appPreferredTouchIcon && [self iconIsBiggerThanFavicon:appPreferredTouchIcon]) {
            self.appIcon = appPreferredTouchIcon;
        } else if (appDefaultTouchIcon && [self iconIsBiggerThanFavicon:appDefaultTouchIcon]) {
            self.appIcon = appDefaultTouchIcon;
        } else if (appFavicon) {
            self.appIcon = appFavicon;
        }
    }
    
    if (appIcon) {
        if (!ifam) {
            ifam = [IconFamily iconFamilyWithThumbnailsOfImage:appIcon usingImageInterpolation:NSImageInterpolationHigh];
        }

        // ifam works better than workspace :-/
        //[[NSWorkspace sharedWorkspace] setIcon:image forFile:bundlePath options:0];
        [ifam setAsCustomIconForDirectory:appDestPath withCompatibility:YES];
        [[NSWorkspace sharedWorkspace] noteFileSystemChanged:appDestPath];
    }
}


- (BOOL)iconIsBiggerThanFavicon:(NSImage *)img {
    if (!appFavicon) return YES;
    
    NSSize faviconSize = [appFavicon size];
    
    NSSize imgSize = [img size];
    return imgSize.width > faviconSize.width && imgSize.height > faviconSize.height;
}


- (void)handleSuccess {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(handleSuccess) withObject:nil waitUntilDone:NO];
        return;
    }
    
    [self playSuccessSound];
    
    NSString *newAppName = [[appName copy] autorelease];
    NSString *newAppDestPath = [[appDestPath copy] autorelease];
    
    NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"Created Fluid App \"%@\".", @""), newAppName];
    
    self.appName = nil;
    self.appURLString = nil;
    self.appDestPath = nil;
    self.appBundleIdentifier = nil;
    self.appIcon = nil;
    self.appCustomIconPath = nil;
    self.appDefaultTouchIcon = nil;
    self.appPreferredTouchIcon = nil;
    self.appFavicon = nil;
    self.busy = NO;
    
    [[self window] makeFirstResponder:appURLTextField];
    
    NSInteger button = NSRunInformationalAlertPanel(NSLocalizedString(@"Success!", @""),
                                                    msg, 
                                                    NSLocalizedString(@"Launch Now", @""), 
                                                    NSLocalizedString(@"Reveal in Finder", @""), 
                                                    NSLocalizedString(@"OK", @""));
    
    switch (button) {
        case BUTTON_OK:
            // no-op
            break;
        case BUTTON_REVEAL:
            [[NSWorkspace sharedWorkspace] selectFile:newAppDestPath inFileViewerRootedAtPath:@"/"];
            break;
        case BUTTON_LAUNCH_NOW:
            [self performSelector:@selector(launchApp:) withObject:newAppDestPath afterDelay:.5];
            break;
        default:
            NSAssert1(0, @"unkown button tag %d", button);
    }
}


- (void)launchApp:(NSString *)path {
    system([[NSString stringWithFormat:@"open %@", path] UTF8String]);
}


- (void)handleError:(NSString *)localizedDescription {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(handleError:) withObject:localizedDescription waitUntilDone:NO];
        return;
    }
    
    NSBeep();
    
    self.busy = NO;
    
    NSRunAlertPanel(NSLocalizedString(@"Could Not Create New Fluid App", @""),
                    localizedDescription, 
                    NSLocalizedString(@"OK", @""), 
                    nil, 
                    nil);
}


- (void)playSuccessSound {
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"done" ofType:@"mov"];
    [[[[NSSound alloc] initWithContentsOfFile:soundPath byReference:YES] autorelease] play];
}


- (NSString *)stringWithSchemeAndTLD:(NSString *)s {
    NSString *URLString = [s stringByEnsuringURLSchemePrefix];
    URLString = [URLString stringByEnsuringTLDSuffix];
    return URLString;
}


#pragma mark -
#pragma mark NSMenuDelegate

- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu {
    return 3;
}


- (void)menuNeedsUpdate:(NSMenu *)menu {
    if (menu == appPathPopUpButtonMenu) {
        [self appPathPopUpButtonMenuNeedsUpdate:menu];
    } else {
        [self appIconPathPopUpButtonMenuNeedsUpdate:menu];
    }
}


- (void)appPathPopUpButtonMenuNeedsUpdate:(NSMenu *)menu {
    [[appPathPopUpButton cell] removeAllItems];
    
    NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:self.appDestDirFolderName
                                                   action:nil
                                            keyEquivalent:@""] autorelease];
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:appDestDir];
    [icon setScalesWhenResized:YES];
    [icon setSize:NSMakeSize(16, 16)];
    [item setImage:icon];
    [item setState:NSOffState];
    [item setEnabled:YES];
    [menu addItem:item];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Other...", @"")
                                       action:@selector(runSelectAppDestDirPanel:)
                                keyEquivalent:@""] autorelease];
    [item setTag:TAG_SELECT_OTHER_APP_PATH];
    [item setTarget:self];
    [item setState:NSOffState];
    [item setEnabled:YES];
    [menu addItem:item];
}


- (void)appIconPathPopUpButtonMenuNeedsUpdate:(NSMenu *)menu {
    [[appIconPathPopUpButton cell] removeAllItems];
    
    NSMenuItem *item = nil;
    
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Use Website Favicon", @"")
                                       action:nil
                                keyEquivalent:@""] autorelease];
    [item setState:NSOffState];
    [item setEnabled:YES];
    [menu addItem:item];
    
    if ([appCustomIconPath length]) {
        [menu addItem:[NSMenuItem separatorItem]];
        
        item = [[[NSMenuItem alloc] initWithTitle:self.appCustomIconPathFolderName
                                           action:nil
                                    keyEquivalent:@""] autorelease];
        
        NSImage *icon = nil;
        if ([self.allowedIconImageExtensions containsObject:[[appCustomIconPath lastPathComponent] pathExtension]]) {
            icon = [[[NSImage alloc] initWithContentsOfFile:appCustomIconPath] autorelease];
        } else if ([[appCustomIconPath pathExtension] isEqualToString:@"icns"]) {
            IconFamily *ifam = [IconFamily iconFamilyWithContentsOfFile:[appCustomIconPath stringByExpandingTildeInPath]];
            icon = [ifam imageWithAllReps];
        } else {
            icon = [[NSWorkspace sharedWorkspace] iconForFile:appCustomIconPath];
        }
        
        [icon setScalesWhenResized:YES];
        [icon setSize:NSMakeSize(16, 16)];
        [item setImage:icon];
        [item setState:NSOffState];
        [item setEnabled:YES];
        [menu addItem:item];
    }
    
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Other...", @"")
                                       action:@selector(runSelectAppDestDirPanel:)
                                keyEquivalent:@""] autorelease];
    [item setTarget:self];
    [item setState:NSOffState];
    [item setEnabled:YES];
    [menu addItem:item];
}


- (IBAction)runSelectAppDestDirPanel:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setAllowsMultipleSelection:NO];
    
    // open panel for select other app location
    if (TAG_SELECT_OTHER_APP_PATH == [sender tag]) {
        [openPanel setCanChooseFiles:NO];
        [openPanel setCanChooseDirectories:YES];
        
    // open panel for select custom icon
    } else {
        [openPanel setCanChooseFiles:YES];
        [openPanel setCanChooseDirectories:NO];
        [openPanel setAllowedFileTypes:self.allowedIconFileExtensions];
    }

    [openPanel beginSheetForDirectory:nil 
                                 file:nil 
                       modalForWindow:[self window]
                        modalDelegate:self
                       didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
                          contextInfo:[sender retain]];    // retained
}


- (void)openPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(NSInteger)code contextInfo:(id)sender {
    [sender autorelease]; // released
    
    // open panel for select other app location
    if (TAG_SELECT_OTHER_APP_PATH == [sender tag]) {
        self.appDestDir = [openPanel filename];
        [self menuNeedsUpdate:appPathPopUpButtonMenu];
        [[appPathPopUpButton cell] selectItemAtIndex:0];

    // open panel for select custom icon
    } else {
        self.appCustomIconPath = [openPanel filename];
        NSInteger i = 0;
        [self menuNeedsUpdate:appIconPathPopUpButtonMenu];
        if ([appCustomIconPath length]) i = INDEX_SELECTED_CUSTOM_ICON_ITEM;
        [[appIconPathPopUpButton cell] selectItemAtIndex:i];
    }
}


#pragma mark -
#pragma mark NSDragginDestination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSDragOperation mask = [sender draggingSourceOperationMask];
    
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        if (mask & NSDragOperationGeneric) {
            NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
            if ([filenames count] && [self.allowedIconFileExtensions containsObject:[[filenames objectAtIndex:0] pathExtension]]) {
                return NSDragOperationCopy;
            }
        }
    }
    
    return NSDragOperationNone;
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
        [self handleDroppedFilenames:filenames];
    }
    return YES;
}


- (void)handleDroppedFilenames:(NSArray *)filenames {
    if ([filenames count]) {
        NSString *filename = [filenames objectAtIndex:0];
        if ([self.allowedIconFileExtensions containsObject:[filename pathExtension]]) {
            self.appCustomIconPath = filename;
            [self menuNeedsUpdate:appIconPathPopUpButtonMenu];
            [[appIconPathPopUpButton cell] selectItemAtIndex:2];
        }
    }
}


#pragma mark -
#pragma mark FluidWebPageLoaderDelegate

- (void)webPageLoader:(FluidWebPageLoader *)loader didFinishLoad:(NSDictionary *)info {
    self.appFavicon = [info objectForKey:FliudWebPageFaviconKey];
    self.appPreferredTouchIcon = [info objectForKey:FluidWebPagePreferredTouchIconKey];
    self.appAllURLStrings = [[[info objectForKey:FluidWebPageAllURLStringsKey] copy] autorelease];
    self.doneLoadingHomePage = YES;
    
    [self checkForDoneFetching];
}


#pragma mark -
#pragma mark Properties

- (FluidWebPageLoader *)webPageLoader {
    if (!webPageLoader) {
        self.webPageLoader = [[[FluidWebPageLoader alloc] initWithDelegate:self] autorelease];
    }
    return webPageLoader;
}


- (NSString *)appDestDirFolderName {
    return [appDestDir lastPathComponent];
}


- (NSString *)appCustomIconPathFolderName {
    return [[appCustomIconPath lastPathComponent] stringByDeletingPathExtension];
}


// dummies for bindings support
- (void)setAppDestDirFolderName:(NSString *)s {}
- (void)setAppCustomIconPathFolderName:(NSString *)s {}


- (NSArray *)allowedIconFileExtensions {
    if (!allowedIconFileExtensions) {
        self.allowedIconFileExtensions = [NSArray arrayWithObjects:@"tiff", @"tif", @"png", @"jpg", @"jpeg", @"icns", @"app", nil];
    }
    return allowedIconFileExtensions;
}


- (NSArray *)allowedIconImageExtensions {
    if (!allowedIconImageExtensions) {
        self.allowedIconImageExtensions = [NSArray arrayWithObjects:@"tiff", @"tif", @"png", @"jpg", @"jpeg", nil];
    }
    return allowedIconImageExtensions;
}

@synthesize appURLTextField;
@synthesize appPathPopUpButton;
@synthesize appPathPopUpButtonMenu;
@synthesize appIconPathPopUpButton;
@synthesize appIconPathPopUpButtonMenu;
@synthesize webPageLoader;
@synthesize appURLString;
@synthesize appBundleIdentifier;
@synthesize appName;
@synthesize appDestDir;
@synthesize appDestPath;
@synthesize appCustomIconPath;
@synthesize appIcon;
@synthesize appLocalCustonIcon;
@synthesize appDefaultTouchIcon;
@synthesize appPreferredTouchIcon;
@synthesize appFavicon;
@synthesize appAllURLStrings;
@synthesize busy;
@synthesize allowedIconFileExtensions;
@synthesize allowedIconImageExtensions;
@synthesize doneCreatingLocalCustomIcon;
@synthesize doneFetchingDefaultTouchIcon;
@synthesize doneLoadingHomePage;
@end
