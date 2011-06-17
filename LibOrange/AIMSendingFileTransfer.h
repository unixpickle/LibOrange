//
//  AIMSendingFileTransfer.h
//  LibOrange
//
//  Created by Alex Nichol on 6/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMFileTransfer.h"
#import "ANIPInformation.h"

@interface AIMSendingFileTransfer : AIMFileTransfer {
    NSString * localFile;
	UInt16 listenPort;
	NSMutableSet * backgroundThreadSet;
	NSMutableSet * mainThreadSet;
}

@property (nonatomic, retain) NSString * localFile;
- (AIMIMRendezvous *)initialProposal;
- (void)listenForConnect;
- (void)gotCounterProposal;

// background thread
- (NSThread *)backgroundThread;
- (void)setBackgroundThread:(NSThread *)newBackgroundThread;
// main thread
- (NSThread *)mainThread;
- (void)setMainThread:(NSThread *)newMainThread;

@end
