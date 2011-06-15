//
//  AIMRendezvousHandler.h
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMSession.h"
#import "AIMReceivingFileTransfer.h"
#import "AIMIMRendezvous.h"

@class AIMRendezvousHandler;

@protocol AIMRendezvousHandlerDelegate <NSObject>

@optional
- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferRequested:(AIMReceivingFileTransfer *)ft;
- (void)aimRendezvousHandler:(AIMRendezvousHandler *)rvHandler fileTransferCancelled:(AIMReceivingFileTransfer *)ft reason:(UInt16)reason;

@end

@interface AIMRendezvousHandler : NSObject <AIMSessionHandler> {
    NSMutableArray * fileTransfers;
	AIMSession * session;
	id<AIMRendezvousHandlerDelegate> delegate;
}

@property (nonatomic, assign) id<AIMRendezvousHandlerDelegate> delegate;

- (id)initWithSession:(AIMSession *)theSession;
- (AIMFileTransfer *)fileTransferWithCookie:(AIMICBMCookie *)cookie;

- (void)acceptFileTransfer:(AIMReceivingFileTransfer *)ft;

@end
