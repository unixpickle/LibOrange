//
//  OSCARConnection.m
//  TalkToOscar
//
//  Created by Alex Nichol on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OSCARConnection.h"

#define kMaxBufferSize 65536

@interface OSCARConnection ()

- (void)readInBackground:(NSThread *)mainThread;
- (void)officialClosedown;
- (void)packetWaiting;
- (void)setIsOpen:(BOOL)_isOpen;

@end

@implementation OSCARConnection

@synthesize hostName;
@synthesize isNonBlocking;
@synthesize sequenceNumber;
@synthesize delegate;

- (BOOL)isOpen {
	[isOpenLock lock];
	BOOL _isOpen = isOpen;
	[isOpenLock unlock];
	return _isOpen;
}

- (id)initWithHost:(NSString *)host port:(int)_port {
	if ((self = [super init])) {
		hostName = [host retain];
		port = _port;
		isOpenLock = [[NSLock alloc] init];
		isOpen = NO;
		isNonBlocking = NO;
		hasDied = NO;
		sequenceNumber = arc4random() % 0xFFFF;
	}
	return self;
}

- (BOOL)connectToHost:(NSError **)error {
	// first, launch the connection.
	if (hasDied || self.isOpen) return NO;
	struct sockaddr_in serv_addr;
	struct hostent * server;
	socketfd = socket(AF_INET, SOCK_STREAM, 0);
	if (socketfd < 0) {
		if (error)
			*error = [NSError errorWithDomain:@"Socket creation failed" code:200 userInfo:nil];
		hasDied = YES;
		return NO;
	}
	
	server = gethostbyname([hostName UTF8String]);
	if (!server) {
		if (error) 
			*error = [NSError errorWithDomain:@"No host" code:201 userInfo:nil];
		hasDied = YES;
		return NO;
	}
	
	bzero(&serv_addr, sizeof(struct sockaddr_in));
	serv_addr.sin_family = AF_INET;
	// copy the address to our sockadd_in.
	bcopy(server->h_addr, &serv_addr.sin_addr.s_addr, server->h_length);
	serv_addr.sin_port = htons(port);
	
	if (connect(socketfd, (const struct sockaddr *)&serv_addr, sizeof(struct sockaddr_in)) < 0) {
		hasDied = YES;
		if (error)
			*error = [NSError errorWithDomain:@"Connect failed" code:202 userInfo:nil];
	}
	
	buffer = [[NSMutableArray alloc] init];
	
	// we have our socket, we need to listen.
	isOpen = YES;
	hasDied = NO;
	
	backgroundThread = [[NSThread alloc] initWithTarget:self
											   selector:@selector(readInBackground:)
												 object:[NSThread currentThread]];
	[backgroundThread start];
	
	return YES;
}

- (BOOL)hasFlap {
	if (![self isOpen]) return NO;
	int count = 0;
	@synchronized (buffer) {
		count = (int)[buffer count];
	}
	return (count > 0) ? YES : NO;
}
- (FLAPFrame *)readFlap {
	if (![self isOpen]) return nil;
	if (isNonBlocking && ![self hasFlap]) return nil;
	if ([self hasFlap]) {
		FLAPFrame * frame = nil;
		@synchronized (buffer) {
			if ([buffer count] < 1) return nil;
			frame = [[buffer objectAtIndex:0] retain];
			[buffer removeObjectAtIndex:0];
		}
		return [frame autorelease];
	} else if (!isNonBlocking) {
		while (![self hasFlap]) {
			// block
			if (![self isOpen]) {
				return nil;
			}
		}
		return [self readFlap];
	}
	return nil;
}

- (FLAPFrame *)createFlapChannel:(UInt8)channel data:(NSData *)contents {
	return [[[FLAPFrame alloc] initWithChannel:channel
								sequenceNumber:sequenceNumber++
										  data:contents] autorelease];
}

- (BOOL)writeFlap:(FLAPFrame *)flap {
	if (![self isOpen]) return NO;
	// we have to execute a write statement
	NSData * bufferData = [flap encodePacket];
	const char * bytes = [bufferData bytes];
	int toWrite = (int)[bufferData length];
	while (toWrite > 0) {
		int needsWritten = (toWrite <= kMaxBufferSize) ? toWrite : kMaxBufferSize;
		int wrote = (int)write(socketfd, &bytes[[bufferData length] - toWrite], needsWritten);
		if (wrote <= 0) {
			[self officialClosedown];
			return NO;
		}
		toWrite -= wrote;
	}
	return YES;
}

- (BOOL)disconnect {
	if (![self isOpen]) return NO;
	if ([NSThread currentThread] != initThread) {
		[self performSelector:@selector(disconnect) onThread:initThread withObject:nil waitUntilDone:YES];
		return YES;
	}
	[backgroundThread cancel];
	[backgroundThread release];
	backgroundThread = nil;
	[self officialClosedown];
	return YES;
}

- (void)dealloc {
	[backgroundThread release];
	[isOpenLock release];
	[hostName release];
	[buffer release];
	[super dealloc];
}

#pragma mark Private

- (void)readInBackground:(NSThread *)mainThread {
	initThread = mainThread;
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	while (![[NSThread currentThread] isCancelled]) {
		
		// first, await some data.
		int error;
		fd_set readDetector;
		struct timeval myVar;
		do {
			FD_ZERO(&readDetector);
			FD_SET(socketfd, &readDetector);
			myVar.tv_sec = 10;
			myVar.tv_usec = 0;
			error = select(socketfd + 1, &readDetector,
							   NULL, NULL, &myVar);
			if (error < 0) {
				[self setIsOpen:NO];
				[self performSelector:@selector(officialClosedown) onThread:mainThread withObject:nil waitUntilDone:NO];
				[pool drain];
				return;
			}
		} while (!FD_ISSET(socketfd, &readDetector) && error <= 0);
		
		// here we read a header's length, and the data.
		int headerGot = 0;
		char headerData[6];
		while (headerGot < 6) {
			int justRead = (int)read(socketfd, &headerData[headerGot], 6 - headerGot);
			if (justRead <= 0) {
				[self setIsOpen:NO];
				[self performSelector:@selector(officialClosedown) onThread:mainThread withObject:nil waitUntilDone:NO];
				[pool drain];
				return;
			}
			headerGot += justRead;
		}
		
		if ([[NSThread currentThread] isCancelled]) break;
		
		UInt16 payloadLength = flipUInt16(((UInt16 *)headerData)[2]);
		int bytesNeeded = payloadLength;
		// read that many bytes!
		char * payload = (char *)malloc(payloadLength);
		while (bytesNeeded > 0) {
			int startIndex = payloadLength - bytesNeeded;
			int wants = (bytesNeeded <= kMaxBufferSize) ? bytesNeeded : kMaxBufferSize;
			int justRead = (int)read(socketfd, &payload[startIndex], wants);
			if (justRead <= 0) {
				free(payload);
				[self setIsOpen:NO];
				[self performSelector:@selector(officialClosedown) onThread:mainThread withObject:nil waitUntilDone:NO];
				[pool drain];
				return;
			}
			bytesNeeded -= justRead;
		}
		
		NSMutableData * frameData = [[NSMutableData alloc] init];
		[frameData appendBytes:headerData length:6];
		[frameData appendBytes:payload length:payloadLength];
		free(payload);
		FLAPFrame * flap = [[FLAPFrame alloc] initWithData:frameData];
		[frameData release];
		
		// finally, add the packet and notify.
		@synchronized (buffer) {
			[buffer addObject:flap];
			[flap release];
		}
		
		[self performSelector:@selector(packetWaiting) onThread:mainThread
				   withObject:nil waitUntilDone:NO];
	}
	
	[self setIsOpen:NO];
	[self performSelector:@selector(officialClosedown) onThread:mainThread
			   withObject:nil waitUntilDone:NO];
	
	[pool drain];
}
- (void)officialClosedown {
	if (hasDied) return;
	[self setIsOpen:NO];
	close(socketfd);
	socketfd = -1;
	if (!hasDied) {
		if ([delegate respondsToSelector:@selector(oscarConnectionClosed:)]) 
			[delegate oscarConnectionClosed:self];
		hasDied = YES;
	}
}
- (void)packetWaiting {
	if ([delegate respondsToSelector:@selector(oscarConnectionPacketWaiting:)]) 
		[delegate oscarConnectionPacketWaiting:self];
}
- (void)setIsOpen:(BOOL)_isOpen {
	[isOpenLock lock];
	isOpen = _isOpen;
	[isOpenLock unlock];
}

@end
