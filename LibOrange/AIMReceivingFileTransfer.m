//
//  AIMReceivingFileTransfer.m
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMReceivingFileTransfer.h"


@implementation AIMReceivingFileTransfer

@synthesize remoteHostAddr;

- (NSString *)description {
	return [NSString stringWithFormat:@"<AIMFileTransfer from %@ (%@)>", self.buddy, remoteHostAddr];
}

- (void)dealloc {
	self.remoteHostAddr = nil;
	[super dealloc];
}

@end
