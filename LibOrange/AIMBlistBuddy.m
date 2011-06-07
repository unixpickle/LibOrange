//
//  AIMBlistBuddy.m
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMBlistBuddy.h"
#import "AIMBlistGroup.h"


@implementation AIMBlistBuddy

@synthesize group;
@synthesize username;
@synthesize feedbagItemID;
@synthesize status;

- (id)initWithUsername:(NSString *)theUsername {
	if ((self = [super init])) {
		username = [theUsername retain];
	}
	return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@", username];
}

- (void)dealloc {
	self.status = nil;
	[username release];
	[super dealloc];
}

@end
