//
//  AIMIMRendezvous.h
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMICBMCookie.h"
#import "AIMCapability.h"
#import "TLV.h"
#import "AIMICBMMessageToClient.h"

#define CANCEL_REASON_UNKNOWN 0
#define CANCEL_REASON_USER_CANCEL 1
#define CANCEL_REASON_TIMEOUT 2
#define CANCEL_REASON_ACCEPTED_ELSEWHERE 3
#define CANCEL_REASON_NOT_CANCELLED 4 // my own value

#define RV_TYPE_PROPOSE 0
#define RV_TYPE_CANCEL 1
#define RV_TYPE_ACCEPT 2

@interface AIMIMRendezvous : NSObject <OSCARPacket> {
    UInt16 type;
	AIMICBMCookie * cookie;
	AIMCapability * service;
	NSArray * params;
}

@property (readwrite) UInt16 type;
@property (nonatomic, retain) AIMICBMCookie * cookie;
@property (nonatomic, retain) AIMCapability * service;
@property (nonatomic, retain) NSArray * params;

- (id)initWithICBMMessage:(AIMICBMMessageToClient *)msg;

- (NSString *)remoteAddress;
- (UInt16)remotePort;
- (UInt16)sequenceNumber;
- (UInt16)cancelReason;

@end
