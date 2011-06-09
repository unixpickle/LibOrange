//
//  MyTest.h
//  LibOrange
//
//  Created by Alex Nichol on 6/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMLogin.h"
#import "AIMSessionManager.h"
#import "FTAddBuddy.h"
#import "FTRemoveBuddy.h"

@interface MyTest : NSObject <AIMLoginDelegate, AIMSessionManagerDelegate, AIMFeedbagHandlerDelegate, AIMICBMHandlerDelegate, AIMStatusHandlerDelegate> {
    AIMLogin * login;
	AIMSessionManager * theSession;
	NSThread * mainThread;
}

- (void)beginTest;
- (void)blockingCheck;
- (void)checkThreading;

- (void)handleAddBuddyMsg:(AIMMessage *)message msgSender:(AIMICBMHandler *)sender;
- (void)handleDelBuddyMsg:(AIMMessage *)message msgSender:(AIMICBMHandler *)sender;

@end
