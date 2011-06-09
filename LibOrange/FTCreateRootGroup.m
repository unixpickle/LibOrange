//
//  FTCreateRootGroup.m
//  LibOrange
//
//  Created by Alex Nichol on 6/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FTCreateRootGroup.h"


@implementation FTCreateRootGroup

- (void)createOperationsWithFeedbag:(AIMFeedbag *)feedbag session:(AIMSession *)session {
	AIMFeedbagItem * rootGroup = [[AIMFeedbagItem alloc] init];
	TLV * blankOrder = [[TLV alloc] initWithType:FEEDBAG_ATTRIBUTE_ORDER data:[NSData data]];
	rootGroup.attributes = [NSArray arrayWithObject:blankOrder];
	rootGroup.classID = FEEDBAG_GROUP;
	rootGroup.groupID = 0;
	rootGroup.itemID = 0;
	rootGroup.itemName = @"";
	
	SNAC * insertSnac = [[SNAC alloc] initWithID:SNAC_ID_NEW(SNAC_FEEDBAG, FEEDBAG__INSERT_ITEMS) flags:0 requestID:[session generateReqID] data:[rootGroup encodePacket]];
	snacs = [[NSArray alloc] initWithObjects:insertSnac, nil];
	
	[rootGroup release];
	[blankOrder release];
	[insertSnac release];
	currentIndex = -1;
}

- (BOOL)hasCreatedOperations {
	if (snacs) return YES;
	else return NO;
}

- (SNAC *)nextTransactionSNAC {
	if (currentIndex + 1 == [snacs count]) return nil;
	return [snacs objectAtIndex:++currentIndex];
}

- (SNAC *)currentTransactionSNAC {
	if (currentIndex < 0) return nil;
	return [snacs objectAtIndex:currentIndex];
}

- (void)dealloc {
	[snacs release];
	[super dealloc];
}

@end
