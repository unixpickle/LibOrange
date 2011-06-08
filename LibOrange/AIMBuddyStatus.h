//
//  AIMBuddyStatus.h
//  LibOrange
//
//  Created by Alex Nichol on 6/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	AIMBuddyStatusAway,
	AIMBuddyStatusAvailable,
	AIMBuddyStatusOffline,
	AIMBuddyStatusRejected
} AIMBuddyStatusType;

@interface AIMBuddyStatus : NSObject {
    NSString * statusMessage;
	AIMBuddyStatusType statusType;
	UInt32 idleTime; // in minutes
}

@property (readonly) NSString * statusMessage;
@property (readonly) AIMBuddyStatusType statusType;
@property (readonly) UInt32 idleTime;

- (id)initWithMessage:(NSString *)message type:(AIMBuddyStatusType)type timeIdle:(UInt32)timeIdle;
+ (AIMBuddyStatus *)offlineStatus;
+ (AIMBuddyStatus *)rejectedStatus;
- (BOOL)isEqualToStatus:(AIMBuddyStatus *)status;

@end
