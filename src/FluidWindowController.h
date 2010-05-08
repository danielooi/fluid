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

#import <Cocoa/Cocoa.h>
#import "FluidWebPageLoader.h"

@class WebView;

@interface FluidWindowController : NSWindowController <FluidWebPageLoaderDelegate> {
    NSTextField *appURLTextField;
    NSPopUpButton *appPathPopUpButton;
    NSMenu *appPathPopUpButtonMenu;
    NSPopUpButton *appIconPathPopUpButton;
    NSMenu *appIconPathPopUpButtonMenu;
    
    FluidWebPageLoader *webPageLoader;
    
    NSString *appURLString;
    NSString *appBundleIdentifier;
    NSString *appName;
    NSString *appDestDir;
    NSString *appDestPath;
    NSString *appCustomIconPath;
    NSImage *appIcon;
    NSImage *appLocalCustonIcon;
    NSImage *appDefaultTouchIcon;
    NSImage *appPreferredTouchIcon;
    NSImage *appFavicon;
    NSArray *appAllURLStrings;
    BOOL busy;
    
    BOOL doneCreatingLocalCustomIcon;
    BOOL doneFetchingDefaultTouchIcon;
    BOOL doneLoadingHomePage;
    
    NSArray *allowedIconFileExtensions;
    NSArray *allowedIconImageExtensions;
}

- (IBAction)run:(id)sender;
- (IBAction)setLocationTo:(id)sender;
- (IBAction)runSelectAppDestDirPanel:(id)sender;

@property (nonatomic, retain) IBOutlet NSTextField *appURLTextField;
@property (nonatomic, retain) IBOutlet NSPopUpButton *appPathPopUpButton;
@property (nonatomic, retain) IBOutlet NSMenu *appPathPopUpButtonMenu;
@property (nonatomic, retain) IBOutlet NSPopUpButton *appIconPathPopUpButton;
@property (nonatomic, retain) IBOutlet NSMenu *appIconPathPopUpButtonMenu;

@property (nonatomic, retain) FluidWebPageLoader *webPageLoader;
@property (nonatomic, copy) NSString *appURLString;
@property (nonatomic, copy) NSString *appBundleIdentifier;
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *appDestDir;
@property (nonatomic, copy) NSString *appDestPath;
@property (nonatomic, copy) NSString *appCustomIconPath;
@property (nonatomic, retain) NSImage *appIcon;
@property (nonatomic, retain) NSImage *appLocalCustonIcon;
@property (nonatomic, retain) NSImage *appDefaultTouchIcon;
@property (nonatomic, retain) NSImage *appPreferredTouchIcon;
@property (nonatomic, retain) NSImage *appFavicon;
@property (nonatomic, retain) NSArray *appAllURLStrings;
@property (nonatomic, retain) NSString *appDestDirFolderName;
@property (nonatomic, retain) NSString *appCustomIconPathFolderName;
@property (nonatomic, retain) NSArray *allowedIconFileExtensions;
@property (nonatomic, retain) NSArray *allowedIconImageExtensions;
@property (assign) BOOL busy;
@property (assign) BOOL doneCreatingLocalCustomIcon;
@property (assign) BOOL doneFetchingDefaultTouchIcon;
@property (assign) BOOL doneLoadingHomePage;
@end
