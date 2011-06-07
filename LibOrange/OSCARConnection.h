//
//  OSCARConnection.h
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h> 
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#import <Foundation/Foundation.h>
#import "flipbit.h"
#import "FLAPFrame.h"

@class OSCARConnection;

@protocol OSCARConnectionDelegate<NSObject>

- (void)oscarConnectionClosed:(OSCARConnection *)connection;

@optional
- (void)oscarConnectionPacketWaiting:(OSCARConnection *)connection;

@end


@interface OSCARConnection : NSObject {
	int socketfd;
	int port;
	NSString * hostName;
	BOOL isOpen;
	BOOL isNonBlocking;
	BOOL hasDied;
	
	NSLock * isOpenLock;
	
	NSThread * backgroundThread;
	NSThread * initThread;
	NSMutableArray * buffer;
	
	id<OSCARConnectionDelegate> delegate;
	
	// OSCAR
	UInt16 sequenceNumber;
}

@property (readonly) NSString * hostName;
@property (readwrite) BOOL isNonBlocking;
@property (readonly) UInt16 sequenceNumber;
@property (readonly) BOOL isOpen;
@property (nonatomic, assign) id<OSCARConnectionDelegate> delegate;

- (id)initWithHost:(NSString *)host port:(int)_port;
- (BOOL)connectToHost:(NSError **)error;

- (BOOL)hasFlap;
- (FLAPFrame *)readFlap;

- (FLAPFrame *)createFlapChannel:(UInt8)channel data:(NSData *)contents;
- (BOOL)writeFlap:(FLAPFrame *)flap;

- (BOOL)disconnect;

@end
