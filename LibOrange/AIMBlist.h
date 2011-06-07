//
//  AIMBlist.h
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMFeedbag.h"
#import "AIMFeedbagItem+Order.h"
#import "AIMBlistGroup.h"
#import "AIMTempBuddyHandler.h"

@interface AIMBlist : NSObject {
    NSMutableArray * groups;
	AIMTempBuddyHandler * tempBuddyHandler;
}

@property (readonly) AIMTempBuddyHandler * tempBuddyHandler;

- (NSArray *)groups;
- (id)initWithFeedbag:(AIMFeedbag *)feedbag tempBuddyHandler:(AIMTempBuddyHandler *)tmpBuddy;

- (AIMBlistBuddy *)buddyWithUsername:(NSString *)username;
- (NSArray *)buddiesWithUsername:(NSString *)username;
- (AIMBlistBuddy *)buddyWithFeedbagID:(UInt16)feedbagID;
- (AIMBlistGroup *)groupWithFeedbagID:(UInt16)feedbagID;

- (AIMBlistGroup *)loadGroup:(AIMFeedbagItem *)group inFeedbag:(AIMFeedbag *)feedbag;

@end
