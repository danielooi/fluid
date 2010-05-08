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
