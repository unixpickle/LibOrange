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
#import "AIMBArtHandler.h"

@class AIMStatusHandler;

@protocol AIMStatusHandlerDelegate<NSObject>

@optional
- (void)aimStatusHandler:(AIMStatusHandler *)handler buddy:(AIMBlistBuddy *)theBuddy statusChanged:(AIMBuddyStatus *)status;
- (void)aimStatusHandler:(AIMStatusHandler *)handler buddyIconChanged:(AIMBlistBuddy *)theBuddy;
- (void)aimStatusHandler:(AIMStatusHandler *)handler buddyRejected:(NSString *)loginID;
- (void)aimStatusHandlerUserStatusUpdated:(AIMStatusHandler *)handler;

@end

@interface AIMStatusHandler : NSObject <AIMSessionHandler, AIMBArtHandlerDelegate> {
    AIMSession * session;
	AIMBuddyStatus * userStatus;
	id<AIMStatusHandlerDelegate> delegate;
	AIMNickWInfo * lastInfo;
	AIMBArtHandler * bartHandler;
}

@property (readonly) AIMBuddyStatus * userStatus;
@property (nonatomic, assign) id<AIMStatusHandlerDelegate> delegate;
@property (nonatomic, retain) AIMBArtHandler * bartHandler;

- (id)initWithSession:(AIMSession *)theSession initialInfo:(AIMNickWInfo *)initInfo;
- (void)queryUserInfo;
- (void)updateStatus:(AIMBuddyStatus *)newStatus;
- (void)configureBart;

@end
