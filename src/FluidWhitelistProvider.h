//
//  FluidWhitelistProvider.h
//  Fluid
//
//  Created by Todd Ditchendorf on 1/11/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FluidWhitelistProvider : NSObject {

}

+ (NSArray *)patternDictsForURLStrings:(NSArray *)a;
@end
