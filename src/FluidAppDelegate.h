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

extern NSString *const kFluidDestinationDirKey;

@class FluidWindowController;
@class FluidPreferencesWindowController;

@interface FluidAppDelegate : NSObject {
    FluidWindowController *windowController;
    FluidPreferencesWindowController *preferencesWindowController;
}

- (IBAction)showMainWindow:(id)sender;
- (IBAction)showPreferencesWindow:(id)sender;

- (IBAction)setLocationTo:(id)sender;

@property (nonatomic, retain) FluidWindowController *windowController;
@property (nonatomic, retain) FluidPreferencesWindowController *preferencesWindowController;
@end
