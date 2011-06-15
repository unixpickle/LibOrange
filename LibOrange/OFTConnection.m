//
//  OFTConnection.m
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OFTConnection.h"

int setNonblocking(int fd) {
    int flags;
    /* If they have O_NONBLOCK, use the Posix way to do it */
#if defined(O_NONBLOCK)
    /* Fixme: O_NONBLOCK is defined but broken on SunOS 4.1.x and AIX 3.2.5. */
    if (-1 == (flags = fcntl(fd, F_GETFL, 0)))
        flags = 0;
    return fcntl(fd, F_SETFL, flags | O_NONBLOCK);
#else
	abort();
#endif
}    

@implementation OFTConnection

- (OFTConnectionState)state {
	[stateLock lock];
	OFTConnectionState stateCopy = state;
	[stateLock unlock];
	return stateCopy;
}

/**
 * Attempts to create a new connection to a specific host and port.
 * If the connect fails, nil will be returned.
 */
- (id)initWithHost:(NSString *)host port:(UInt16)port {
	if ((self = [super init])) {
		stateLock = [[NSLock alloc] init];
		fileDescriptorLock = [[NSLock alloc] init];
		state = OFTConnectionStateUnopen;
		// TODO: connect socket here.
		struct sockaddr_in serv_addr;
		struct hostent * server;
		fileDescriptor = socket(AF_INET, SOCK_STREAM, 0);
		if (fileDescriptor < 0) {
			[self dealloc];
			return nil;
		}
		
		server = gethostbyname([host UTF8String]);
		if (!server) {
			[self dealloc];
			return nil;
		}
		
		bzero(&serv_addr, sizeof(struct sockaddr_in));
		serv_addr.sin_family = AF_INET;
		// copy the address to our sockadd_in.
		bcopy(server->h_addr, &serv_addr.sin_addr.s_addr, server->h_length);
		serv_addr.sin_port = htons(port);
		
		// set non-blocking.
		
		
		if (connect(fileDescriptor, (const struct sockaddr *)&serv_addr, sizeof(struct sockaddr_in)) < 0) {
			[self dealloc];
			return nil;
		}
		
		fd_set fdset;
		struct timeval tv;
		FD_ZERO(&fdset);
		FD_SET(fileDescriptor, &fdset);
		tv.tv_sec = 10;			/* 10 second timeout */
		tv.tv_usec = 0;
		
		if (select(fileDescriptor + 1, NULL, &fdset, NULL, &tv) == 1) {
			int so_error;
			socklen_t len = sizeof so_error;
			getsockopt(fileDescriptor, SOL_SOCKET, SO_ERROR, &so_error, &len);
			if (so_error != 0) {
				[super dealloc];
				return nil;
			}
		}
	}
	return self;
}

/**
 * Creates an OFT connection with an existing file descriptor.
 */
- (id)initWithFileDescriptor:(int)fd {
	if ((self = [super init])) {
		stateLock = [[NSLock alloc] init];
		fileDescriptorLock = [[NSLock alloc] init];
		state = OFTConnectionStateOpen;
		fileDescriptor = fd;
	}
	return self;
}

@end
