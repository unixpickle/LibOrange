//
//  AIMRendezvousHandler.m
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMRendezvousHandler.h"

@interface AIMRendezvousHandler (Private)

- (void)_handleRendezvousMessage:(AIMICBMMessageToClient *)message;
- (void)_handleReceiving:(AIMReceivingFileTransfer *)ft rvMessage:(AIMIMRendezvous *)msg;

@end

@implementation AIMRendezvousHandler

@synthesize delegate;

- (id)initWithSession:(AIMSession *)theSession {
	if ((self = [super init])) {
		fileTransfers = [[NSMutableArray alloc] init];
		session = [theSession retain];
		[session addHandler:self];
	}
	return self;
}

- (void)handleIncomingSnac:(SNAC *)aSnac {
	NSAssert([NSThread currentThread] == [session backgroundThread], @"Running on incorrect thread");
	if (SNAC_ID_IS_EQUAL(SNAC_ID_NEW(SNAC_ICBM, ICBM__CHANNEL_MSG_TOCLIENT), [aSnac snac_id])) {
		AIMICBMMessageToClient * message = [[AIMICBMMessageToClient alloc] initWithData:[aSnac innerContents]];
		if ([message channel] == 2) {
			[self performSelector:@selector(_handleRendezvousMessage:) onThread:session.mainThread withObject:message waitUntilDone:NO];
		}
		[message release];
	}
}

- (void)sessionClosed {
	// TODO: cancel all transfers.
	[fileTransfers release];
	fileTransfers = nil;
	[session removeHandler:self];
	[session release];
	session = nil;
}

- (AIMFileTransfer *)fileTransferWithCookie:(AIMICBMCookie *)cookie {
	NSAssert([NSThread currentThread] == [session mainThread], @"Running on incorrect thread");
	for (AIMFileTransfer * transfer in fileTransfers) {
		if ([[transfer cookie] isEqualToCookie:cookie]) {
			return transfer;
		}
	}
	return nil;
}

- (void)acceptFileTransfer:(AIMReceivingFileTransfer *)ft {
	// send the information.
	AIMIMRendezvous * lastProp = [ft lastProposal];
	NSLog(@"Connect to %@:%d", [lastProp remoteAddress], [lastProp remotePort]);
	
}

- (void)_handleRendezvousMessage:(AIMICBMMessageToClient *)message {
	NSAssert([NSThread currentThread] == [session mainThread], @"Running on incorrect thread");
	AIMFileTransfer * ft = [self fileTransferWithCookie:[message cookie]];
	if (!ft) {
		AIMReceivingFileTransfer * newTransfer = [[AIMReceivingFileTransfer alloc] initWithCookie:[message cookie]];
		[fileTransfers addObject:newTransfer];
		newTransfer.buddy = [[session buddyList] buddyWithUsername:[message.nickInfo username]];
		ft = [newTransfer autorelease];
	}
	// populate with information.
	AIMIMRendezvous * rvMessage = [[AIMIMRendezvous alloc] initWithICBMMessage:message];
	if ([ft isKindOfClass:[AIMReceivingFileTransfer class]]) {
		[self _handleReceiving:(AIMReceivingFileTransfer *)ft rvMessage:rvMessage];
	}
	[rvMessage release];
}

- (void)_handleReceiving:(AIMReceivingFileTransfer *)ft rvMessage:(AIMIMRendezvous *)msg {
	NSAssert([NSThread currentThread] == [session mainThread], @"Running on incorrect thread");
	if ([msg sequenceNumber] == 1 && [msg type] == RV_TYPE_PROPOSE) {
		[ft setRemoteHostAddr:[msg remoteAddress]];
		[ft setLastProposal:msg];
		if ([delegate respondsToSelector:@selector(aimRendezvousHandler:fileTransferRequested:)]) {
			[delegate aimRendezvousHandler:self fileTransferRequested:ft];
		}
	} else if ([msg type] == RV_TYPE_CANCEL) {
		[ft setWasCancelled:YES];
		if ([delegate respondsToSelector:@selector(aimRendezvousHandler:fileTransferCancelled:reason:)]) {
			[delegate aimRendezvousHandler:self fileTransferCancelled:ft reason:[msg cancelReason]];
		}
		[fileTransfers removeObject:ft];
	}
}

- (void)dealloc {
	[session release];
	[fileTransfers release];
	[super dealloc];
}

@end
