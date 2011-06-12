//
//  AIMBArtHandler.h
//  LibOrange
//
//  Created by Alex Nichol on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SNAC.h"
#import "AIMBArtIDWName.h"
#import "OSCARConnection.h"
#import "AIMSession.h"
#import "AIMBuddyIcon.h"
#import "AIMBArtDownloadReply.h"

@class AIMBArtHandler;

@protocol AIMBArtHandlerDelegate <NSObject>

@optional
- (void)aimBArtHandlerConnectedToBArt:(AIMBArtHandler *)handler;
- (void)aimBArtHandlerConnectFailed:(AIMBArtHandler *)handler;
- (void)aimBArtHandlerDisconnected:(AIMBArtHandler *)handler;
- (void)aimBArtHandler:(AIMBArtHandler *)handler gotBuddyIcon:(AIMBuddyIcon *)icns forUser:(NSString *)loginID;

@end

@interface AIMBArtHandler : NSObject <AIMSessionHandler, OSCARConnectionDelegate> {
    NSString * bartHost;
	NSData * bartCookie;
	OSCARConnection * currentConnection;
	AIMSession * bossSession;
	id<AIMBArtHandlerDelegate> delegate;
}

@property (nonatomic, retain) id<AIMBArtHandlerDelegate> delegate;

- (id)initWithSession:(AIMSession *)aSession;
- (BOOL)startupBArt;
- (void)closeBArtConnection;

- (BOOL)fetchBArtIcon:(AIMBArtID *)bartID forUser:(NSString *)username;

@end
