//
//  AIMStatusHandler.h
//  LibOrange
//
//  Created by Alex Nichol on 6/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMSession.h"
#import "AIMNickWInfo.h"
#import "AIMNickWInfo+BArt.h"
#import "AIMNickWInfo+Update.h"

@class AIMStatusHandler;

@protocol AIMStatusHandlerDelegate<NSObject>

@optional
- (void)aimStatusHandler:(AIMStatusHandler *)handler buddy:(AIMBlistBuddy *)theBuddy statusChanged:(AIMBuddyStatus *)status;
- (void)aimStatusHandler:(AIMStatusHandler *)handler buddyRejected:(NSString *)loginID;
- (void)aimStatusHandlerUserStatusUpdated:(AIMStatusHandler *)handler;

@end

@interface AIMStatusHandler : NSObject <AIMSessionHandler> {
    AIMSession * session;
	AIMBuddyStatus * userStatus;
	id<AIMStatusHandlerDelegate> delegate;
	AIMNickWInfo * lastInfo;
}

@property (readonly) AIMBuddyStatus * userStatus;
@property (nonatomic, assign) id<AIMStatusHandlerDelegate> delegate;

- (id)initWithSession:(AIMSession *)theSession initialInfo:(AIMNickWInfo *)initInfo;
- (void)queryUserInfo;
- (void)updateStatus:(AIMBuddyStatus *)newStatus;

@end
