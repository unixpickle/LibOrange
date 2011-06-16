//
//  AIMReceivingFileTransfer.m
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AIMReceivingFileTransfer.h"

@interface AIMReceivingFileTransfer (Private)

- (void)backgroundThread:(NSDictionary *)proposalInfo;
- (void)receiveFileDirectly:(OFTConnection *)theConnection;
- (OFTConnection *)configureProxy:(NSString *)ipAddress port:(UInt16)port cookie:(NSData *)cookie sn:(NSString *)screenName;
- (void)_delegateInformCounterProp:(AIMIMRendezvous *)counter;
- (AIMIMRendezvous *)connectHereCounterProposal:(UInt16)port cookie:(NSData *)cookieData;
+ (TLV *)capabilitiesBlock;

@end

@implementation AIMReceivingFileTransfer

@synthesize remoteHostAddr;
@synthesize remoteFileName;
@synthesize delegate;
@synthesize localUsername;

- (NSThread *)mainThread {
	[mainThreadLock lock];
	NSThread * theMainThread = mainThread;
	[mainThreadLock unlock];
	return theMainThread;
}

- (void)setMainThread:(NSThread *)_mainThread {
	[mainThreadLock lock];
	[mainThread autorelease];
	mainThread = [_mainThread retain];
	[mainThreadLock unlock];
}

- (NSThread *)backgroundThread {
	[bgThreadLock lock];
	NSThread * bgThread = backgroundThread;
	[bgThreadLock unlock];
	return bgThread;
}

- (void)setBackgroundThread:(NSThread *)_backgroundThread {
	[bgThreadLock lock];
	[backgroundThread autorelease];
	backgroundThread = [_backgroundThread retain];
	[bgThreadLock unlock];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<AIMFileTransfer name=\"%@\" source=\"%@ (%@)\">", self.remoteFileName, self.buddy, remoteHostAddr];
}

- (void)tryProposal {
	if (!bgThreadLock) {
		bgThreadLock = [[NSLock alloc] init];
	}
	if (!mainThreadLock) {
		mainThreadLock = [[NSLock alloc] init];
	}
	NSAssert(!self.backgroundThread, @"Background thread already running");
	
	NSString * ipCopy = [[[self lastProposal] remoteAddress] copy];
	NSString * internalIpCopy = [[[self lastProposal] internalAddress] copy];
	NSString * proxyIpCopy = [[[self lastProposal] proxyAddress] copy];
	UInt16 port = [[self lastProposal] remotePort];
	BOOL isProxy = [[self lastProposal] isProxyFlagSet];
	NSNumber * proxyFlag = [NSNumber numberWithBool:isProxy];
	NSNumber * step = [NSNumber numberWithInt:[[self lastProposal] sequenceNumber]];
	NSData * cookieDataCopy = [[[self cookie] cookieData] copy];
	NSString * snCopy = [self.localUsername copy]; // TODO: make this async.
	
	if (!internalIpCopy) internalIpCopy = [@"" retain];
	if (!ipCopy) ipCopy = [@"" retain];
	
	NSDictionary * connectInf = [NSDictionary dictionaryWithObjectsAndKeys:ipCopy, @"IP", internalIpCopy, @"IN_IP", [NSNumber numberWithInt:port], @"Port", proxyFlag, @"Proxy", proxyIpCopy, @"ProxyAddr", step, @"Seq", snCopy, @"SN", cookieDataCopy, @"CookieData", nil];
	
	[proxyIpCopy release];
	[ipCopy release];
	[internalIpCopy release];
	[cookieDataCopy release];
	[snCopy release];
	
	self.mainThread = [NSThread currentThread];
	self.backgroundThread = [[[NSThread alloc] initWithTarget:self selector:@selector(backgroundThread:) object:connectInf] autorelease];
	[self.backgroundThread start];
}

- (void)backgroundThread:(NSDictionary *)proposalInfo {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSString * ipAddr = [proposalInfo objectForKey:@"IP"];
	NSString * internalAddr = [proposalInfo objectForKey:@"IN_IP"];
	NSString * sn = [proposalInfo objectForKey:@"SN"];
	NSString * proxyIp = [proposalInfo objectForKey:@"ProxyAddr"];
	NSData * cookieData = [proposalInfo objectForKey:@"CookieData"];
	// UInt16 stage = [[proposalInfo objectForKey:@"Seq"] unsignedShortValue];
	
	UInt16 port = (UInt16)[[proposalInfo objectForKey:@"Port"] intValue];
	// UInt16 sequenceNumber = (UInt16)[[proposalInfo objectForKey:@"Seq"] intValue];
	BOOL useProxy = [[proposalInfo objectForKey:@"Proxy"] boolValue];
	if (useProxy) {
		OFTConnection * proxyConn = nil;
		if (!(proxyConn = [self configureProxy:proxyIp port:port cookie:cookieData sn:sn])) {
			NSLog(@"Proxy connection failed to load.");
			if ([delegate respondsToSelector:@selector(aimReceivingFileTransferTransferFailed:)]) {
				[(NSObject *)delegate performSelector:@selector(aimReceivingFileTransferTransferFailed:) onThread:self.mainThread withObject:self waitUntilDone:NO];
			}
		} else {
			NSLog(@"Proxy connected!");
			if ([delegate respondsToSelector:@selector(aimReceivingFileTransferSendAccept:)]) {
				[(NSObject *)delegate performSelector:@selector(aimReceivingFileTransferSendAccept:) onThread:self.mainThread withObject:self waitUntilDone:NO];
			}
			[self receiveFileDirectly:proxyConn];
		}
	} else {
		OFTConnection * connection = [[OFTConnection alloc] initWithHost:ipAddr port:port];
		if (!connection) {
			OFTConnection * connection = [[OFTConnection alloc] initWithHost:internalAddr port:port];
			if (!connection) {
				// generate counter proposal.
				UInt16 port = (UInt16)((arc4random() % (65535 - 6000)) + 6000);
				NSLog(@"Proposal port: %d", port);
				AIMIMRendezvous * counterProp = [self connectHereCounterProposal:port cookie:cookieData];
				OFTServer * server = [[OFTServer alloc] initWithPort:port];
				[self performSelector:@selector(_delegateInformCounterProp:) onThread:self.mainThread withObject:counterProp waitUntilDone:NO];
				NSLog(@"Opening port, generating proposal for it.");
				int fd = [server fileDescriptorForListeningOnPort:30]; // 30 second timeout.
				[server closeServer];
				[server release];
				if (fd < 0) {
					self.backgroundThread = nil;
					[pool drain];
					return;
				} else {
					NSLog(@"Got connect to ourselves.");
					OFTConnection * connection = [[OFTConnection alloc] initWithFileDescriptor:fd];
					[self receiveFileDirectly:connection];
					[connection release];
				}
			} else {
				NSLog(@"Connect success (internal IP)... start downloading the file.");
				if ([delegate respondsToSelector:@selector(aimReceivingFileTransferSendAccept:)]) {
					[(NSObject *)delegate performSelector:@selector(aimReceivingFileTransferSendAccept:) onThread:self.mainThread withObject:self waitUntilDone:NO];
				}
				[self receiveFileDirectly:connection];
				[connection release];
			}
		} else {
			// get the file.
			NSLog(@"Connect success (external IP)... start downloading the file.");
			if ([delegate respondsToSelector:@selector(aimReceivingFileTransferSendAccept:)]) {
				[(NSObject *)delegate performSelector:@selector(aimReceivingFileTransferSendAccept:) onThread:self.mainThread withObject:self waitUntilDone:NO];
			}
			[self receiveFileDirectly:connection];
			[connection release];
		}
	}
	
	self.backgroundThread = nil;
	[pool drain];
}

- (void)newProposal {
	// if it's accepting, it will die silently.
	[self.backgroundThread cancel];
	self.backgroundThread = nil;
	[self tryProposal];
}

- (AIMIMRendezvous *)connectHereCounterProposal:(UInt16)port cookie:(NSData *)cookieData {
	// get our IP address.
	UInt32 ipAddress = [ANIPInformation ipAddressGuess];
	UInt32 ipAddrConf =  ipAddress ^ 0xFFFFFFFF;
	UInt16 portDat = flipUInt16(port);
	UInt16 portConf = portDat ^ 0xFFFF;
	UInt16 requestNumFlip = flipUInt16(2);
	TLV * tIpAddr = [[TLV alloc] initWithType:TLV_RV_IP_ADDR data:[NSData dataWithBytes:&ipAddress length:4]];
	TLV * tClientAddr = [[TLV alloc] initWithType:TLV_RV_PROPOSER_IP_ADDR data:[NSData dataWithBytes:&ipAddress length:4]];
	TLV * tIpAddrXor = [[TLV alloc] initWithType:TLV_RV_IP_ADDR_XOR data:[NSData dataWithBytes:&ipAddrConf length:4]];
	TLV * tPort = [[TLV alloc] initWithType:TLV_RV_PORT data:[NSData dataWithBytes:&portDat length:2]];
	TLV * tPortXor = [[TLV alloc] initWithType:TLV_RV_PORT_XOR data:[NSData dataWithBytes:&portConf length:2]];
	TLV * reqNumber = [[TLV alloc] initWithType:TLV_RV_SEQUENCE_NUM data:[NSData dataWithBytes:&requestNumFlip length:2]];
	AIMIMRendezvous * rendezvous = [[AIMIMRendezvous alloc] init];
	rendezvous.cookie = [[[AIMICBMCookie alloc] initWithCookieData:[cookieData bytes]] autorelease];
	rendezvous.service = [[[AIMCapability alloc] initWithType:AIMCapabilityFileTransfer] autorelease];
	rendezvous.type = RV_TYPE_PROPOSE;
	rendezvous.params = [NSArray arrayWithObjects:reqNumber, tIpAddr, tIpAddrXor, tClientAddr, tPort, tPortXor, nil];
	[tIpAddr release];
	[tClientAddr release];
	[tIpAddrXor release];
	[tPort release];
	[tPortXor release];
	[reqNumber release];
	return [rendezvous autorelease];
}

- (void)_delegateInformCounterProp:(AIMIMRendezvous *)counter {
	if ([delegate respondsToSelector:@selector(aimReceivingFileTransferPropositionFailed:counterProposal:)]) {
		[delegate aimReceivingFileTransferPropositionFailed:self counterProposal:counter];
	}
}

#pragma mark Direct Connection

- (void)receiveFileDirectly:(OFTConnection *)theConnection {
	// TODO: here is where we should interact with the OSCAR File Transfer server.
	// This method should download the file's data and write it to a local file.
	// Every buffer downloaded should update the progress.
	NSLog(@"Receive file directly: %@", theConnection);
	if ([delegate respondsToSelector:@selector(aimReceivingFileTransferStarted:)]) {
		[(NSObject *)delegate performSelector:@selector(aimReceivingFileTransferStarted:) onThread:self.mainThread withObject:self waitUntilDone:NO];
	}
	sleep(2);
	NSLog(@"Cancelling transfer.");
	[theConnection closeConnection];
}

- (OFTConnection *)configureProxy:(NSString *)ipAddress port:(UInt16)port cookie:(NSData *)_cookie sn:(NSString *)screenName {
	UInt16 actualPort = 5190;
	OFTConnection * realConnection = [[OFTConnection alloc] initWithHost:ipAddress port:actualPort];
	if (!realConnection) return nil;
	OFTProxyConnection * proxy = [[OFTProxyConnection alloc] initWithFileDescriptor:[realConnection fileDescriptor]];
	
	// configure the proxy.
	NSMutableData * initRecv = [[NSMutableData alloc] init];
	UInt8 snLen = (UInt8)[screenName length];
	UInt16 portFlip = flipUInt16(port);
	TLV * caps = [AIMReceivingFileTransfer capabilitiesBlock];
	[initRecv appendBytes:&snLen length:1];
	[initRecv appendData:[screenName dataUsingEncoding:NSASCIIStringEncoding]];
	[initRecv appendBytes:&portFlip length:2];
	[initRecv appendData:_cookie];
	[initRecv appendData:[caps encodePacket]];
	
	OFTProxyCommand * cmd = [[[OFTProxyCommand alloc] initWithCommandType:COMMAND_TYPE_INIT_RECV flags:0 cmdData:initRecv] autorelease];
	[initRecv release];
	if (![proxy writeCommand:cmd]) {
		[proxy release];
		[realConnection release];
		return nil;
	}
	OFTProxyCommand * conf = [proxy readCommand];
	if (!conf || [conf commandType] != COMMAND_TYPE_READY) {
		NSLog(@"error info: %@", [conf commandData]);
		[proxy release];
		[realConnection release];
		return nil;
	}
	
	[proxy release];
	return [realConnection autorelease];
}
															  
+ (TLV *)capabilitiesBlock {
	char caps[16];
	memcpy(caps, "\x09\x46\x13\x43\x4C\x7F\x11\xD1\x82\x22\x44\x45\x53\x54", 14);
	caps[14] = 0;
	caps[15] = 0;
	return [[[TLV alloc] initWithType:1 data:[NSData dataWithBytes:caps length:16]] autorelease];
}

- (void)dealloc {
	self.remoteHostAddr = nil;
	self.remoteFileName = nil;
	self.mainThread = nil;
	self.backgroundThread = nil;
	self.delegate = nil;
	self.localUsername = nil;
	[mainThreadLock release];
	[bgThreadLock release];
	[super dealloc];
}

@end
