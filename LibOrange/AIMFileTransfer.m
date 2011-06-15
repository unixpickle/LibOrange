//
//  AIMFileTransfer.m
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMFileTransfer.h"


@implementation AIMFileTransfer

@synthesize cookie;
@synthesize buddy;
@synthesize wasCancelled;
@synthesize lastProposal;

- (id)initWithCookie:(AIMICBMCookie *)theCookie {
	if ((self = [super init])) {
		cookie = [theCookie retain];
	}
	return self;
}

- (NSString *)description {
	return [super description];
}

- (void)dealloc {
	[cookie release];
	self.buddy = nil;
	self.lastProposal = nil;
	[super dealloc];
}

@end
