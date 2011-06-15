//
//  AIMFileTransfer.h
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMICBMCookie.h"
#import "AIMICBMMessageToClient.h"
#import "AIMBlistBuddy.h"
#import "AIMIMRendezvous.h"


@interface AIMFileTransfer : NSObject {
	AIMICBMCookie * cookie;
	AIMBlistBuddy * buddy;
	BOOL wasCancelled;
	AIMIMRendezvous * lastProposal;
}

@property (readonly) AIMICBMCookie * cookie;
@property (nonatomic, retain) AIMBlistBuddy * buddy;
@property (readwrite) BOOL wasCancelled;
@property (nonatomic, retain) AIMIMRendezvous * lastProposal;

- (id)initWithCookie:(AIMICBMCookie *)theCookie;

@end
