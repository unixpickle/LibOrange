//
//  AIMFeedbagHandler.h
//  LibOrange
//
//  Created by Alex Nichol on 6/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMSession.h"
#import "AIMFeedbag.h"
#import "AIMFeedbagRights.h"
#import "AIMTempBuddyHandler.h"

@class AIMFeedbagHandler;

@protocol AIMFeedbagHandlerDelegate <NSObject>

@optional
- (void)aimFeedbagHandlerGotBuddyList:(AIMFeedbagHandler *)feedbagHandler;
- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyDeleted:(AIMBlistBuddy *)oldBuddy;
- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender buddyAdded:(AIMBlistBuddy *)newBuddy;
- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender groupAdded:(AIMBlistGroup *)newGroup;
- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender groupDeleted:(AIMBlistGroup *)oldGroup;
- (void)aimFeedbagHandler:(AIMFeedbagHandler *)sender groupRenamed:(AIMBlistGroup *)theGroup;

@end

@interface AIMFeedbagHandler : NSObject <AIMSessionHandler> {
    AIMSession * session;
	AIMFeedbag * feedbag;
	AIMFeedbagRights * feedbagRights;
	AIMTempBuddyHandler * tempBuddyHandler;
	id<AIMFeedbagHandlerDelegate> delegate;
}

@property (readonly) AIMFeedbag * feedbag;
@property (readonly) AIMSession * session;
@property (nonatomic, assign) AIMTempBuddyHandler * tempBuddyHandler;
@property (nonatomic, retain) AIMFeedbagRights * feedbagRights;
@property (nonatomic, assign) id<AIMFeedbagHandlerDelegate> delegate;

- (id)initWithSession:(AIMSession *)theSession;
- (BOOL)sendFeedbagRequest;

@end
