//
//  AIMSendingFileTransfer.m
//  LibOrange
//
//  Created by Alex Nichol on 6/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMSendingFileTransfer.h"

@interface AIMSendingFileTransfer (Private)

- (void)listenBackgroundThread:(NSDictionary *)info;
- (void)connectInBackground:(NSDictionary *)info;
- (void)connectToProxy;

@end

@implementation AIMSendingFileTransfer

@synthesize localFile;

- (id)init {
    if ((self = [super init])) {
		
    }
    return self;
}

- (AIMIMRendezvous *)initialProposal {
	NSFileHandle * fh = [NSFileHandle fileHandleForReadingAtPath:[self localFile]];
	if (!fh) return nil;
	[fh seekToEndOfFile];
	NSUInteger size = [fh offsetInFile];
	[fh closeFile];
	
	char * filenameEncoding = "us-ascii";
	UInt16 seqNum = flipUInt16(1);
	UInt32 ipAddr = [ANIPInformation ipAddressGuess];
	UInt32 ipAddrXor = ipAddr ^ 0xFFFFFFFF;
	UInt16 port = flipUInt16((UInt16)(arc4random() % (65535 - 1024)) + 1024);
	UInt16 portXor = port ^ 0xFFFF;
	UInt16 maxProto = flipUInt16(1);
	listenPort = flipUInt16(port);
	
	RVServiceData * sCaps = [[RVServiceData alloc] init];
	sCaps.fileName = [localFile lastPathComponent];
	sCaps.multipleFilesFlag = 1;
	sCaps.totalFileCount = 1;
	sCaps.totalBytes = (UInt32)size;
	
	if (![sCaps encodePacket]) {
		[sCaps release];
		return nil;
	}
	
	TLV * seqNumber = [[TLV alloc] initWithType:TLV_RV_SEQUENCE_NUM data:[NSData dataWithBytes:&seqNum length:2]];
	TLV * ipAddress = [[TLV alloc] initWithType:TLV_RV_IP_ADDR data:[NSData dataWithBytes:&ipAddr length:4]];
	TLV * xorIpAddress = [[TLV alloc] initWithType:TLV_RV_IP_ADDR_XOR data:[NSData dataWithBytes:&ipAddrXor length:4]];
	TLV * t_port = [[TLV alloc] initWithType:TLV_RV_PORT data:[NSData dataWithBytes:&port length:2]];
	TLV * t_portXor = [[TLV alloc] initWithType:TLV_RV_PORT_XOR data:[NSData dataWithBytes:&portXor length:2]];
	TLV * cliIp = [[TLV alloc] initWithType:TLV_RV_PROPOSER_IP_ADDR data:[NSData dataWithBytes:&ipAddr length:4]];
	TLV * fnameEnc = [[TLV alloc] initWithType:TLV_RV_FILENAME_ENCODING data:[NSData dataWithBytes:filenameEncoding length:8]];
	TLV * capabilityData = [[TLV alloc] initWithType:TLV_RV_SERVICE_DATA data:[sCaps encodePacket]];
	TLV * maxProtoVer = [[TLV alloc] initWithType:TLV_RV_MAX_PROTOCOL_VERSION data:[NSData dataWithBytes:&maxProto length:2]];
	[sCaps release];
	
	AIMIMRendezvous * rv = [[AIMIMRendezvous alloc] init];
	rv.cookie = self.cookie;
	rv.service = [[[AIMCapability alloc] initWithType:AIMCapabilityFileTransfer] autorelease];
	rv.type = RV_TYPE_PROPOSE;
	rv.params = [NSArray arrayWithObjects:seqNumber, ipAddress, xorIpAddress, cliIp, t_port, t_portXor, fnameEnc, capabilityData, maxProtoVer, nil];
	
	[seqNumber release];
	[ipAddress release];
	[xorIpAddress release];
	[t_port release];
	[t_portXor release];
	[cliIp release];
	[fnameEnc release];
	[capabilityData release];
	[maxProtoVer release];
	
	return [rv autorelease];
}

- (void)listenForConnect {
	NSData * cookieCopy = [[[[self cookie] cookieData] copy] autorelease];
	NSDictionary * info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:listenPort], @"port", cookieCopy, @"cookie", nil];
	self.mainThread = [NSThread currentThread];
	self.backgroundThread = [[[NSThread alloc] initWithTarget:self selector:@selector(listenBackgroundThread:) object:info] autorelease];
	[self.backgroundThread start];
}
- (void)gotCounterProposal {
	NSLog(@"Counter prop");
	[self.backgroundThread cancel];
	self.backgroundThread = nil;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<AIMSendingFileTransfer path=\"%@\" buddy=\"%@\">", self.localFile, self.buddy];
}

#pragma mark Background Thread

- (void)listenBackgroundThread:(NSDictionary *)info {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	UInt16 port = [[info objectForKey:@"port"] unsignedShortValue];
	NSData * cookieData = [info objectForKey:@"cookie"];
	NSLog(@"Todo: listen on port %d for cookie %@", port, cookieData);
	[pool drain];
}
- (void)connectInBackground:(NSDictionary *)info {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	[pool drain];
}
- (void)connectToProxy {
	
}

#pragma mark Synchronized Setters/Getters

// background thread
- (NSThread *)backgroundThread {
	if (!backgroundThreadSet) {
		backgroundThreadSet = [[NSMutableSet alloc] init];
	}
	@synchronized (backgroundThreadSet) {
		if ([backgroundThreadSet count] != 1) return nil;
		return (NSThread *)[backgroundThreadSet anyObject];
	}
}
- (void)setBackgroundThread:(NSThread *)newBackgroundThread {
	if (!backgroundThreadSet) {
		backgroundThreadSet = [[NSMutableSet alloc] init];
	}
	@synchronized (mainThreadSet) {
		[backgroundThreadSet removeAllObjects];
		if (newBackgroundThread) [backgroundThreadSet addObject:newBackgroundThread];
	}
}
// main thread
- (NSThread *)mainThread {
	if (!mainThreadSet) {
		mainThreadSet = [[NSMutableSet alloc] init];
	}
	@synchronized (mainThreadSet) {
		if ([mainThreadSet count] != 1) return nil;
		return (NSThread *)[mainThreadSet anyObject];
	}
}
- (void)setMainThread:(NSThread *)newMainThread {
	if (!mainThreadSet) {
		mainThreadSet = [[NSMutableSet alloc] init];
	}
	@synchronized (mainThreadSet) {
		[mainThreadSet removeAllObjects];
		if (newMainThread) [mainThreadSet addObject:newMainThread];
	}
}

- (void)dealloc {
	[mainThreadSet release];
	[backgroundThreadSet release];
	self.localFile = nil;
    [super dealloc];
}

@end
