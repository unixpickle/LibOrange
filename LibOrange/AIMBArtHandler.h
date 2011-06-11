//
//  AIMBArtHandler.h
//  LibOrange
//
//  Created by Alex Nichol on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SNAC.h"
#import "AIMBArtID.h"
#import "OSCARConnection.h"
#import "AIMSession.h"

@class AIMBArtHandler;

@protocol AIMBArtHandlerDelegate <NSObject>

@optional
- (void)aimBArtHandlerConnectedToBArt:(AIMBArtHandler *)handler;
- (void)aimBArtHandlerConnectFailed:(AIMBArtHandler *)handler;
- (void)aimBArtHandlerDisconnected:(AIMBArtHandler *)handler;

@end

@interface AIMBArtHandler : NSObject <AIMSessionHandler, OSCARConnectionDelegate> {
    NSString * bartHost;
	NSData * bartCookie;
	OSCARConnection * currentConnection;
	AIMSession * bossSession;
	id<AIMBArtHandlerDelegate> delegate;
}

@property (nonatomic, assign) id<AIMBArtHandlerDelegate> delegate;

- (id)initWithSession:(AIMSession *)aSession;
- (BOOL)startupBArt;

@end
