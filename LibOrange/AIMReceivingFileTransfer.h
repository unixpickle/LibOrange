//
//  AIMReceivingFileTransfer.h
//  LibOrange
//
//  Created by Alex Nichol on 6/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIMFileTransfer.h"

@interface AIMReceivingFileTransfer : AIMFileTransfer {
    NSString * remoteHostAddr;
}

@property (nonatomic, retain) NSString * remoteHostAddr;

@end
