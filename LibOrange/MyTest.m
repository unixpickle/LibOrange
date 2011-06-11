//
//  MyTest.m
//  LibOrange
//
//  Created by Alex Nichol on 6/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MyTest.h"

#define kSignoffTime 120

static void stripNL (char * buff) {
	if (strlen(buff) == 0) return;
	if (buff[strlen(buff) - 1] == '\n') {
		buff[strlen(buff) - 1] = 0;
	}
}

@implementation MyTest

- (void)beginTest {
	printf("LibOrange (v: %s): -beginTest\n", lib_orange_version_string);
	mainThread = [NSThread currentThread];
	char buffer[512];
	printf("Enter username: ");
	fgets(buffer, 512, stdin);
	stripNL(buffer);
	NSString * username = [NSString stringWithUTF8String:buffer];
	
	printf("Enter password: ");
	fgets(buffer, 512, stdin);
	stripNL(buffer);
	NSString * password = [NSString stringWithUTF8String:buffer];
	
	login = [[AIMLogin alloc] initWithUsername:username password:password];
	[login setDelegate:self];
	if (![login beginAuthorization]) {
		NSLog(@"Failed to start authenticating.");
		abort();
	}
	[self blockingCheck];
}

- (void)blockingCheck {
	static NSDate * lastTime = nil;
	if (!lastTime) {
		lastTime = [[NSDate date] retain];
	} else {
		NSDate * newTime = [NSDate date];
		NSTimeInterval ti = [newTime timeIntervalSinceDate:lastTime];
		if (ti > 0.2) {
			NSLog(@"Main thread blocked for %d milliseconds.", (int)round(ti * 1000.0));
		}
		[lastTime release];
		lastTime = [newTime retain];
	}
	[self performSelector:@selector(blockingCheck) withObject:nil afterDelay:0.05];
}

- (void)checkThreading {
	if ([NSThread currentThread] != mainThread) {
		NSLog(@"warning: NOT RUNNING ON MAIN THREAD!");
	}
}

#pragma mark Login Delegate

- (void)aimLogin:(AIMLogin *)theLogin failedWithError:(NSError *)error {
	[self checkThreading];
	NSLog(@"AIM login failed: %@", error);
	[login release];
	exit(-1);
}

- (void)aimLogin:(AIMLogin *)theLogin openedSession:(AIMSessionManager *)session {
	[self checkThreading];
	[session setDelegate:self];
	[login release];
	login = nil;
	theSession = [session retain];
	
	/* Set handler delegates */
	session.feedbagHandler.delegate = self;
	session.messageHandler.delegate = self;
	session.statusHandler.delegate = self;
	
	[session configureBuddyArt];
	AIMBuddyStatus * newStatus = [[AIMBuddyStatus alloc] initWithMessage:@"Using LibOrange on Mac!" type:AIMBuddyStatusAvailable timeIdle:0];
	[session.statusHandler updateStatus:newStatus];
	[newStatus release];
	
	NSLog(@"Got session: %@", session);
	NSLog(@"Our status: %@", session.statusHandler.userStatus);
	NSLog(@"Disconnecting in %d seconds ...", kSignoffTime);
	[[session session] performSelector:@selector(closeConnection) withObject:nil afterDelay:kSignoffTime];
}

#pragma mark Session Delegate

- (void)aimSessionManagerSignedOff:(AIMSessionManager *)sender {
	[self checkThreading];
	[theSession autorelease];
	theSession = nil;
	NSLog(@"Session signed off");
}

#pragma mark Buddy List Methods

- (void)aimFeedbagHandlerGotBuddyList:(AIMFeedbagHandler *)feedbagHandler {
	[self checkThreading];
	NSLog(@"%@ got the buddy list.", feedbagHandler);
	NSLog(@"Blist: %@", [theSession.session buddyList]);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyAdded:(AIMBlistBuddy *)newBuddy {
	[self checkThreading];
	NSLog(@"Buddy added: %@", newBuddy);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyDeleted:(AIMBlistBuddy *)oldBuddy {
	[self checkThreading];
	NSLog(@"Buddy removed: %@", oldBuddy);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender groupAdded:(AIMBlistGroup *)newGroup {
	[self checkThreading];
	NSLog(@"Group added: %@", [newGroup name]);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender groupDeleted:(AIMBlistGroup *)oldGroup {
	[self checkThreading];
	NSLog(@"Group removed: %@", [oldGroup name]);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender groupRenamed:(AIMBlistGroup *)theGroup {
	[self checkThreading];
	NSLog(@"Group renamed: %@", [theGroup name]);
	NSLog(@"Blist: %@", theSession.session.buddyList);
}

- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender transactionFailed:(id<FeedbagTransaction>)transaction {
	[self checkThreading];
	NSLog(@"Transaction failed: %@", transaction);
}

#pragma mark Message Handler

- (void)aimICBMHandler:(AIMICBMHandler *)sender gotMessage:(AIMMessage *)message {
	[self checkThreading];
	
	NSString * msgTxt = [message plainTextMessage];
	
	NSString * autoresp = [message isAutoresponse] ? @" (Auto-Response)" : @"";
	NSLog(@"(%@) %@%@: %@", [NSDate date], [[message buddy] username], autoresp, [message plainTextMessage]);
	
	NSArray * tokens = [CommandTokenizer tokensOfCommand:msgTxt];
	if ([tokens count] == 1) {
		if ([[tokens objectAtIndex:0] isEqual:@"blist"]) {
			NSString * desc = [[theSession.session buddyList] description];
			[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[desc stringByAddingAOLRTFTags]]];
		}
	} else if ([tokens count] == 2) {
		if ([[tokens objectAtIndex:0] isEqual:@"delbuddy"]) {
			NSString * buddy = [tokens objectAtIndex:1];
			NSString * msg = [self removeBuddy:buddy];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"addgroup"]) {
			NSString * group = [tokens objectAtIndex:1];
			NSString * msg = [self addGroup:group];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		} else if ([[tokens objectAtIndex:0] isEqual:@"delgroup"]) {
			NSString * group = [tokens objectAtIndex:1];
			NSString * msg = [self deleteGroup:group];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		}
	} else if ([tokens count] == 3) {
		if ([[tokens objectAtIndex:0] isEqual:@"addbuddy"]) {
			NSString * group = [tokens objectAtIndex:1];
			NSString * buddy = [tokens objectAtIndex:2];
			NSString * msg = [self addBuddy:buddy toGroup:group];
			if (msg) {
				[sender sendMessage:[AIMMessage messageWithBuddy:[message buddy] message:[msg stringByAddingAOLRTFTags]]];
			}
		}
	}
}

- (void)aimICBMHandler:(AIMICBMHandler *)sender gotMissedCall:(AIMMissedCall *)missedCall {
	[self checkThreading];
	NSLog(@"Missed call from %@", [missedCall buddy]);
}

#pragma mark Status Handler

- (void)aimStatusHandler:(AIMStatusHandler *)handler buddy:(AIMBlistBuddy *)theBuddy statusChanged:(AIMBuddyStatus *)status {
	[self checkThreading];
	NSLog(@"\"%@\"%s%@", theBuddy, ".status = ", status);
}

- (void)aimStatusHandlerUserStatusUpdated:(AIMStatusHandler *)handler {
	[self checkThreading];
	NSLog(@"user.status = %@", [handler userStatus]);
}

- (void)aimStatusHandler:(AIMStatusHandler *)handler buddyIconChanged:(AIMBlistBuddy *)theBuddy {
	[self checkThreading];
	NSString * dirPath = [NSString stringWithFormat:@"%@/Desktop/buddyicons/", NSHomeDirectory()];
	if ([[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
		NSString * path = nil;
		AIMBuddyIconFormat fmt = [[theBuddy buddyIcon] iconDataFormat];
		switch (fmt) {
			case AIMBuddyIconBMPFormat:
				path = [dirPath stringByAppendingFormat:@"%@.bmp", [theBuddy username]];
				break;
			case AIMBuddyIconGIFFormat:
				path = [dirPath stringByAppendingFormat:@"%@.gif", [theBuddy username]];
				break;
			case AIMBuddyIconJPEGFormat:
				path = [dirPath stringByAppendingFormat:@"%@.jpg", [theBuddy username]];
				break;
			default:
				break;
		}
		if (path) {
			[[[theBuddy buddyIcon] iconData] writeToFile:path atomically:YES];
		}
	}
}

#pragma mark Commands

- (NSString *)removeBuddy:(NSString *)username {
	AIMBlistBuddy * buddy = [theSession.session.buddyList buddyWithUsername:username];
	if (buddy && [buddy group]) {
		FTRemoveBuddy * remove = [[FTRemoveBuddy alloc] initWithBuddy:buddy];
		[theSession.feedbagHandler pushTransaction:remove];
		[remove release];
		return @"Remove (buddy) request sent.";
	} else {
		return @"Err: buddy not found.";
	}
}
- (NSString *)addBuddy:(NSString *)username toGroup:(NSString *)groupName {
	AIMBlistGroup * group = [theSession.session.buddyList groupWithName:groupName];
	if (!group) {
		return @"Err: group not found.";
	}
	AIMBlistBuddy * buddy = [group buddyWithUsername:username];
	if (buddy) {
		return @"Err: buddy exists.";
	}
	FTAddBuddy * addBudd = [[FTAddBuddy alloc] initWithUsername:username group:group];
	[theSession.feedbagHandler pushTransaction:addBudd];
	[addBudd release];
	return @"Add (buddy) request sent.";
}
- (NSString *)deleteGroup:(NSString *)groupName {
	AIMBlistGroup * group = [theSession.session.buddyList groupWithName:groupName];
	if (!group) {
		return @"Err: group not found.";
	}
	FTRemoveGroup * delGrp = [[FTRemoveGroup alloc] initWithGroup:group];
	[theSession.feedbagHandler pushTransaction:delGrp];
	[delGrp release];
	return @"Delete (group) request sent.";
}
- (NSString *)addGroup:(NSString *)groupName {
	AIMBlistGroup * group = [theSession.session.buddyList groupWithName:groupName];
	if (group) {
		return @"Err: group exists.";
	}
	FTAddGroup * addGrp = [[FTAddGroup alloc] initWithName:groupName];
	[theSession.feedbagHandler pushTransaction:addGrp];
	[addGrp release];
	return @"Add (group) request sent.";
}

@end
