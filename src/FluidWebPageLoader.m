//
//  FluidWebPageLoader.m
//  Fluid
//
//  Created by Todd Ditchendorf on 1/9/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "FluidWebPageLoader.h"
#import "NSString+FUAdditions.h"
#import <WebKit/WebKit.h>

NSString *const FliudWebPageFaviconKey = @"FliudWebPageFavicon";
NSString *const FluidWebPagePreferredTouchIconKey = @"FluidWebPagePreferredTouchIcon";
NSString *const FluidWebPageAllURLStringsKey = @"FluidWebPageAllURLStrings";

@interface FluidWebPageLoader ()
- (void)setUpWebView;
- (NSString *)appleTouchIconURLStringForWebFrame:(WebFrame *)frame;
- (NSString *)hrefForLinkElementWithRelAttribute:(NSString *)attrValue fromWebFrame:(WebFrame *)frame;
- (NSString *)baseURLStringForWebFrame:(WebFrame *)frame;
- (void)fetchPreferredTouchIcon:(NSString *)URLString;
- (void)didFinishFetchingPreferredTouchIcon;
- (void)didFinishLoad;
- (void)checkForDone;
- (void)done;
@end

@implementation FluidWebPageLoader

- (id)initWithDelegate:(id <FluidWebPageLoaderDelegate>)d {
    if (self = [super init]) {
        self.delegate = d;
        [self setUpWebView];
    }
    return self;
}


- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    self.delegate = nil;
    self.webView = nil;
    self.preferredTouchIcon = nil;
    self.favicon = nil;
    self.allURLStrings = nil;
    [super dealloc];
}


- (BOOL)respondsToSelector:(SEL)sel {
    if (@selector(webView:didReceiveIcon:forFrame:) == sel) {
        return YES;
    } else {
        return [super respondsToSelector:sel];
    }
}


#pragma mark -
#pragma mark Public

- (void)loadRequest:(NSURLRequest *)req {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(loadRequest:) withObject:req waitUntilDone:NO];
        return;
    }
    
    self.preferredTouchIcon = nil;
    self.favicon = nil;
    self.allURLStrings = [NSMutableSet set];
    self.doneFetchingPreferredTouchIcon = NO;
    self.doneLoading = NO;
    
    NSString *s = [[req URL] absoluteString];
    [allURLStrings addObject:s];
    
    [[webView mainFrame] loadRequest:req];
}


#pragma mark -
#pragma mark Private

- (void)setUpWebView {
    self.webView = [[[WebView alloc] initWithFrame:NSMakeRect(0, 0, 800, 640)] autorelease];
    [webView setFrameLoadDelegate:self];
    
    WebPreferences *prefs = [WebPreferences standardPreferences];
    [prefs setPrivateBrowsingEnabled:YES];
    [prefs setCacheModel:WebCacheModelDocumentViewer];
    [prefs setUsesPageCache:NO];
    
    [prefs setJavaScriptEnabled:YES]; // ??
    [prefs setJavaScriptCanOpenWindowsAutomatically:NO];
    
    [prefs setJavaEnabled:NO];
    [prefs setPlugInsEnabled:NO];
    
    [prefs setLoadsImagesAutomatically:NO];
    [prefs setAllowsAnimatedImages:NO];
    [prefs setAllowsAnimatedImageLooping:NO];
    
    [webView setPreferences:prefs];
}


- (NSString *)appleTouchIconURLStringForWebFrame:(WebFrame *)frame {
    NSString *URLString = [self hrefForLinkElementWithRelAttribute:@"fluid-icon" fromWebFrame:frame];
    if (![URLString length]) {
        URLString = [self hrefForLinkElementWithRelAttribute:@"apple-touch-icon" fromWebFrame:frame];
    }
    return URLString;
}


- (NSString *)hrefForLinkElementWithRelAttribute:(NSString *)attrValue fromWebFrame:(WebFrame *)frame {
    NSString *baseURLString = [self baseURLStringForWebFrame:frame];
    DOMNodeList *linkEls = [[frame DOMDocument] getElementsByTagName:@"link"];
    NSInteger len = [linkEls length];
    NSInteger i = 0;
    for ( ; i < len; i++) {
        DOMElement *linkEl = (DOMElement *)[linkEls item:i];
        if ([[[linkEl getAttribute:@"rel"] lowercaseString] isEqualToString:attrValue]) {
            NSString *URLString = [linkEl getAttribute:@"href"];
            if (![URLString hasHTTPSchemePrefix]) {
                URLString = [NSString stringWithFormat:@"%@/%@", baseURLString, URLString];
            }
            return URLString;
        }
    }
    return nil;
}


- (NSString *)baseURLStringForWebFrame:(WebFrame *)frame {
    NSString *frameURLString = [[frame webView] mainFrameURL];
    if ([frameURLString hasSuffix:@"/"]) {
        return frameURLString;
    } else {
        return [[frameURLString stringByDeletingPathExtension] stringByDeletingLastPathComponent];
    }
}


- (void)fetchPreferredTouchIcon:(NSString *)URLString {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    self.preferredTouchIcon = [[[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:URLString]] autorelease];
    [self didFinishFetchingPreferredTouchIcon];
    
    [pool release];
}


- (void)didFinishFetchingPreferredTouchIcon {
    self.doneFetchingPreferredTouchIcon = YES;
    [self checkForDone];
}


- (void)didFinishLoad {
    self.doneLoading = YES;
    [self checkForDone];
}


- (void)checkForDone {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(checkForDone) withObject:nil waitUntilDone:NO];
        return;
    }
    
    @synchronized (self) {
        if (self.doneFetchingPreferredTouchIcon && self.doneLoading) {
            self.doneFetchingPreferredTouchIcon = NO;
            self.doneLoading = NO;
            [self performSelector:@selector(done) withObject:self afterDelay:0];
        }
    }
}


- (void)done {
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:3];
    if (favicon) [info setObject:favicon forKey:FliudWebPageFaviconKey];
    if (preferredTouchIcon) [info setObject:preferredTouchIcon forKey:FluidWebPagePreferredTouchIconKey];
    if (allURLStrings) [info setObject:[allURLStrings allObjects] forKey:FluidWebPageAllURLStringsKey];
    
    self.favicon = nil;
    self.preferredTouchIcon = nil;
    self.allURLStrings = nil;
    
    if (delegate) {
        [delegate webPageLoader:self didFinishLoad:info];
    }
}


#pragma mark -
#pragma mark WebFrameLoadDelegate

- (void)webView:(WebView *)sender didReceiveServerRedirectForProvisionalLoadForFrame:(WebFrame *)frame {
    
}


- (void)webView:(WebView *)wv didFailProvisionalLoadWithError:(NSError *)err forFrame:(WebFrame *)frame {
    if (frame != [wv mainFrame]) return;
    
    [self didFinishLoad];
}


- (void)webView:(WebView *)wv didCommitLoadForFrame:(WebFrame *)frame {
    
}


- (void)webView:(WebView *)wv didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame {
    if (frame != [wv mainFrame]) return;
    
    self.favicon = image;
}


- (void)webView:(WebView *)sender willPerformClientRedirectToURL:(NSURL *)URL delay:(NSTimeInterval)seconds fireDate:(NSDate *)date forFrame:(WebFrame *)frame {
    [allURLStrings addObject:[URL absoluteString]];
}


- (void)webView:(WebView *)wv didFinishLoadForFrame:(WebFrame *)frame {
    if (frame != [wv mainFrame]) return;

    NSString *URLString = [self appleTouchIconURLStringForWebFrame:frame];
    if ([URLString length]) {
        [self fetchPreferredTouchIcon:URLString];
    } else {
        [self didFinishFetchingPreferredTouchIcon];
    }

    [self didFinishLoad];
}


- (void)webView:(WebView *)wv didFailLoadWithError:(NSError *)err forFrame:(WebFrame *)frame {
    if (frame != [wv mainFrame]) return;

    [self didFinishLoad];
}


@synthesize delegate;
@synthesize webView;
@synthesize preferredTouchIcon;
@synthesize favicon;
@synthesize allURLStrings;
@synthesize doneFetchingPreferredTouchIcon;
@synthesize doneLoading;
@end
