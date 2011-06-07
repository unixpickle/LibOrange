//
//  AIMStatusHandler.m
//  LibOrange
//
//  Created by Alex Nichol on 6/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMStatusHandler.h"

@interface AIMStatusHandler (Private)

- (void)handleBuddyArrived:(AIMNickWInfo *)nickInfo;
- (void)handleBuddyDeparted:(AIMNickWInfo *)nickInfo;
- (void)handleBuddyRejected:(NSString *)rejected;
- (AIMBuddyStatus *)statusFromNickInfo:(AIMNickWInfo *)info fetchAwayData:(BOOL *)fetchAway;

@end

@implementation AIMStatusHandler

@synthesize delegate;

- (id)initWithSession:(AIMSession *)theSession {
	if ((self = [super init])) {
		session = theSession;
		[theSession addHandler:self];
	}
	return self;
}

- (void)handleIncomingSnac:(SNAC *)aSnac {
	NSAssert([NSThread currentThread] == session.backgroundThread, @"Running on incorrect thread");
	if (SNAC_ID_IS_EQUAL(SNAC_ID_NEW(SNAC_BUDDY, BUDDY__ARRIVED), [aSnac snac_id])) {
		NSArray * arrivedPeople = [AIMNickWInfo decodeArray:[aSnac innerContents]];
		for (AIMNickWInfo * nickInf in arrivedPeople) {
			[self performSelector:@selector(handleBuddyArrived:) onThread:session.mainThread withObject:nickInf waitUntilDone:NO];
		}
	} else if (SNAC_ID_IS_EQUAL(SNAC_ID_NEW(SNAC_BUDDY, BUDDY__DEPARTED), [aSnac snac_id])) {
		NSArray * departedPeople = [AIMNickWInfo decodeArray:[aSnac innerContents]];
		for (AIMNickWInfo * nickInf in departedPeople) {
			[self performSelector:@selector(handleBuddyDeparted:) onThread:session.mainThread withObject:nickInf waitUntilDone:NO];
		}
	} else if (SNAC_ID_IS_EQUAL(SNAC_ID_NEW(SNAC_BUDDY, BUDDY__REJECT_NOTIFICATION), [aSnac snac_id])) {
		NSArray * rejectedPeople = decodeString8Array([aSnac innerContents]);
		for (NSString * uname in rejectedPeople) {
			[self performSelector:@selector(handleBuddyRejected:) onThread:session.mainThread withObject:uname waitUntilDone:NO];
		}
	} else if (SNAC_ID_IS_EQUAL(SNAC_ID_NEW(SNAC_BUDDY, 1), [aSnac snac_id])) {
		NSLog(@"BUDDY error.");
	}
}

- (AIMBuddyStatus *)statusFromNickInfo:(AIMNickWInfo *)info fetchAwayData:(BOOL *)fetchAway {
	UInt16 unavailable = [info nickFlags] & NICKFLAGS_UNAVAILABLE;
	if (unavailable != 0) {
		if (fetchAway) *fetchAway = NO;
	} else if (fetchAway) *fetchAway = YES;
	
	AIMBuddyStatusType type = AIMBuddyStatusAvailable;
	if (unavailable != 0) type = AIMBuddyStatusAway;
	
	UInt16 idleTime = 0;
	for (TLV * t in [info userAttributes]) {
		if ([t type] == TLV_IDLE_TIME && [[t tlvData] length] == 2) {
			idleTime = flipUInt16(*(const UInt16 *)[[t tlvData] bytes]);
		}
	}
	
	NSString * statusMessage = @"";
	// TODO: extract BART status text.
	return [[[AIMBuddyStatus alloc] initWithMessage:statusMessage type:type timeIdle:idleTime] autorelease];
}

#pragma mark Arrived & Departed

- (void)handleBuddyArrived:(AIMNickWInfo *)nickInfo {
	NSAssert([NSThread currentThread] == session.mainThread, @"Running on incorrect thread");
	if ([nickInfo nickFlags] == 0) {
		[self handleBuddyDeparted:nickInfo];
	} else {
		// buddy is online, extract their status and set their stuff.
		BOOL wantsAwayData = NO;
		AIMBuddyStatus * status = [self statusFromNickInfo:nickInfo fetchAwayData:&wantsAwayData];
		NSArray * allBuddies = [[session buddyList] buddiesWithUsername:[nickInfo username]];
		for (AIMBlistBuddy * buddy in allBuddies) {
			if ([delegate respondsToSelector:@selector(aimStatusHandler:buddy:statusChanged:)]) {
				[delegate aimStatusHandler:self buddy:buddy statusChanged:status];
			}
			[buddy setStatus:status];
		}
	}
}
- (void)handleBuddyDeparted:(AIMNickWInfo *)nickInfo {
	NSAssert([NSThread currentThread] == session.mainThread, @"Running on incorrect thread");
	AIMBuddyStatus * status = [AIMBuddyStatus offlineStatus];
	NSArray * allBuddies = [[session buddyList] buddiesWithUsername:[nickInfo username]];
	for (AIMBlistBuddy * buddy in allBuddies) {
		if ([delegate respondsToSelector:@selector(aimStatusHandler:buddy:statusChanged:)]) {
			[delegate aimStatusHandler:self buddy:buddy statusChanged:status];
		}
		[buddy setStatus:status];
	}
}

- (void)handleBuddyRejected:(NSString *)rejected {
	NSAssert([NSThread currentThread] == session.mainThread, @"Running on incorrect thread");
	if ([delegate respondsToSelector:@selector(aimStatusHandler:buddyRejected:)]) {
		[delegate aimStatusHandler:self buddyRejected:rejected];
	}
	AIMBuddyStatus * status = [AIMBuddyStatus rejectedStatus];
	NSArray * allBuddies = [[session buddyList] buddiesWithUsername:rejected];
	for (AIMBlistBuddy * buddy in allBuddies) {
		if ([delegate respondsToSelector:@selector(aimStatusHandler:buddy:statusChanged:)]) {
			[delegate aimStatusHandler:self buddy:buddy statusChanged:status];
		}
		[buddy setStatus:status];
	}
}

@end
