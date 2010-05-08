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

@class WebView;
@class FluidWebPageLoader;

extern NSString *const FliudWebPageFaviconKey;
extern NSString *const FluidWebPagePreferredTouchIconKey;
extern NSString *const FluidWebPageAllURLStringsKey;

@protocol FluidWebPageLoaderDelegate <NSObject>
@required
- (void)webPageLoader:(FluidWebPageLoader *)loader didFinishLoad:(NSDictionary *)info;
@end

@interface FluidWebPageLoader : NSObject {
    id <FluidWebPageLoaderDelegate>delegate;
    WebView *webView;
    NSImage *preferredTouchIcon;
    NSImage *favicon;
    NSMutableSet *allURLStrings;
    
    BOOL doneFetchingPreferredTouchIcon;
    BOOL doneLoading;
}

- (id)initWithDelegate:(id <FluidWebPageLoaderDelegate>)d;

- (void)loadRequest:(NSURLRequest *)req;

@property (nonatomic, assign) id <FluidWebPageLoaderDelegate>delegate;
@property (nonatomic, retain) WebView *webView;
@property (nonatomic, retain) NSImage *preferredTouchIcon;
@property (nonatomic, retain) NSImage *favicon;
@property (nonatomic, retain) NSMutableSet *allURLStrings;
@property (assign) BOOL doneFetchingPreferredTouchIcon;
@property (assign) BOOL doneLoading;
@end
