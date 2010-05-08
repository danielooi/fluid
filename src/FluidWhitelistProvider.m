//
//  FluidWhitelistProvider.m
//  Fluid
//
//  Created by Todd Ditchendorf on 1/11/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "FluidWhitelistProvider.h"
#import "NSString+FUAdditions.h"

static NSDictionary *sSpecialCases = nil;

@interface FluidWhitelistProvider ()
+ (NSString *)hostForURLString:(NSString *)inURLString;
+ (NSString *)patternForHost:(NSString *)host;
+ (NSDictionary *)patternDictForPattern:(NSString *)pattern;
@end

@implementation FluidWhitelistProvider

+ (void)initialize {
    if ([FluidWhitelistProvider class] == self) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"SpecialCases" ofType:@"plist"];
        sSpecialCases = [[NSDictionary alloc] initWithContentsOfFile:path];
    }
}

// array of dicts: @"value" => @"*example.com*". these are dicts cuz they use bindings and undo in the UI
+ (NSArray *)patternDictsForURLStrings:(NSArray *)a {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[a count]];
    NSMutableDictionary *foundPatterns = [NSMutableDictionary dictionaryWithCapacity:[a count]];
    
    for (NSString *URLString in a) {
        NSString *host = [self hostForURLString:URLString];
        
        NSMutableArray *patterns = [NSMutableArray array];
        
        NSString *pattern = [self patternForHost:host];
        if (pattern) {
            [patterns addObject:pattern];
        }
        
        [patterns addObjectsFromArray:[sSpecialCases objectForKey:host]];
        
        for (NSString *pattern in patterns) {
            if ([pattern length] && ![foundPatterns objectForKey:pattern]) {
                [result addObject:[self patternDictForPattern:pattern]];
                [foundPatterns setObject:[NSNull null] forKey:pattern];
            }
        }
        
    }
    
    return result;
}


+ (NSString *)hostForURLString:(NSString *)inURLString {
    NSString *URLString = [inURLString stringByEnsuringURLSchemePrefix];    
    NSString *host = [[NSURL URLWithString:URLString] host];
    if (![host length]) {
        host = inURLString;
    }
    
    return host;
}


+ (NSString *)patternForHost:(NSString *)host {
    if ([host length]) {
        return [NSString stringWithFormat:@"*%@*", host];
    } else {
        return nil;
    }
}


+ (NSDictionary *)patternDictForPattern:(NSString *)pattern {
    if ([pattern length]) {
        return [NSDictionary dictionaryWithObject:pattern forKey:@"value"];
    } else {
        return nil;
    }
}

@end
