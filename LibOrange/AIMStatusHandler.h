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

@class AIMStatusHandler;

@protocol AIMStatusHandlerDelegate<NSObject>

@optional
- (void)aimStatusHandler:(AIMStatusHandler *)handler buddy:(AIMBlistBuddy *)theBuddy statusChanged:(AIMBuddyStatus *)status;
- (void)aimStatusHandler:(AIMStatusHandler *)handler buddyRejected:(NSString *)loginID;

@end

@interface AIMStatusHandler : NSObject <AIMSessionHandler> {
    AIMSession * session;
	id<AIMStatusHandlerDelegate> delegate;
}

@property (nonatomic, assign) id<AIMStatusHandlerDelegate> delegate;

- (id)initWithSession:(AIMSession *)theSession;

@end
