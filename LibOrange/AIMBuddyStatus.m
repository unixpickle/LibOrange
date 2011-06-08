//
//  AIMBuddyStatus.m
//  LibOrange
//
//  Created by Alex Nichol on 6/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMBuddyStatus.h"


@implementation AIMBuddyStatus

@synthesize statusMessage;
@synthesize statusType;
@synthesize idleTime;

- (id)initWithMessage:(NSString *)message type:(AIMBuddyStatusType)type timeIdle:(UInt32)timeIdle {
	if ((self = [super init])) {
		statusMessage = [message retain];
		statusType = type;
		idleTime = timeIdle;
	}
	return self;
}

+ (AIMBuddyStatus *)offlineStatus {
	AIMBuddyStatus * stat = [[AIMBuddyStatus alloc] initWithMessage:@"" type:AIMBuddyStatusOffline timeIdle:0];
	return [stat autorelease];
}

+ (AIMBuddyStatus *)rejectedStatus {
	AIMBuddyStatus * stat = [[AIMBuddyStatus alloc] initWithMessage:@"" type:AIMBuddyStatusRejected timeIdle:0];
	return [stat autorelease];
}

- (BOOL)isEqualToStatus:(AIMBuddyStatus *)status {
	if ([status statusType] == [self statusType] && [[status statusMessage] isEqual:[self statusMessage]] && [status idleTime] == [self idleTime]) return YES;
	return NO;
}

- (NSString *)description {
	NSString * statusTypeStr = @"Offline";
	if (statusType == AIMBuddyStatusAway) statusTypeStr = @"Away";
	else if (statusType == AIMBuddyStatusAvailable) statusTypeStr = @"Available";
	return [NSString stringWithFormat:@"<%@ msg=\"%@\" idle=%d>", 
			statusTypeStr, statusMessage, idleTime];
}

- (void)dealloc {
	[statusMessage release];
	[super dealloc];
}

@end
