//
//  FluidWebPageLoader.h
//  Fluid
//
//  Created by Todd Ditchendorf on 1/9/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

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
