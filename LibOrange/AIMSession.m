//
//  AIMSession.m
//  LibOrange
//
//  Created by Alex Nichol on 6/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMSession.h"


@implementation AIMSession

@synthesize connection;
@synthesize mainThread;
@synthesize backgroundThread;
@synthesize sessionDelegate;
@synthesize buddyList;

- (id)initWithConnection:(OSCARConnection *)theConnection {
	if ((self = [super init])) {
		handlers = [[NSMutableArray alloc] init];
		connection = [theConnection retain];
		[connection setDelegate:self];
	}
	return self;
}

- (void)addHandler:(id<AIMSessionHandler>)aHandler {
	[handlers addObject:aHandler];
}
- (void)removeHandler:(id<AIMSessionHandler>)theHandler {
	[handlers removeObject:theHandler];
}
- (void)closeConnection {
	[connection disconnect];
}

- (UInt32)generateReqID {
	if (!reqID) {
		reqID = arc4random();
	}
	reqID += 1;
	if (!reqID) reqID = 1;
	if (reqID >= 2147483648) reqID ^= 2147483648;
	return reqID;
}
- (BOOL)writeSnac:(SNAC *)aSnac {
	NSData * packetData = [aSnac encodePacket];
	FLAPFrame * flap = [connection createFlapChannel:2
											  data:packetData];
	return [connection writeFlap:flap];
}

#pragma mark OSCAR Connection

- (void)oscarConnectionClosed:(OSCARConnection *)theConnection {
	[backgroundThread cancel];
	backgroundThread = nil;
	// NSLog(@"Closed!");
	if ([sessionDelegate respondsToSelector:@selector(aimSessionClosed:)]) {
		[sessionDelegate performSelector:@selector(aimSessionClosed:) onThread:mainThread withObject:nil waitUntilDone:NO];
	}
	[connection release];
	connection = nil;
}

- (void)oscarConnectionPacketWaiting:(OSCARConnection *)theConnection {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	FLAPFrame * packet = [theConnection readFlap];
	if (packet) {
		SNAC * theSnac = [[SNAC alloc] initWithData:[packet frameData]];
		if (theSnac) {
			for (id<AIMSessionHandler> handler in handlers) {
				[handler handleIncomingSnac:theSnac];
			}
		}
		[theSnac release];
	}
	[pool drain];
}

- (void)dealloc {
	self.buddyList = nil;
	[handlers release];
	[connection release];
	[super dealloc];
}

@end
