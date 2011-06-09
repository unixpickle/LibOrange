//
//  NSString+AOLRTF.m
//  LibOrange
//
//  Created by Alex Nichol on 6/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSString+AOLRTF.h"


@implementation NSString (AOLRTF)

- (NSString *)stringByRemovingAOLRTFTags {
	NSMutableString * newString = [NSMutableString string];
	int depth = 0;
	NSMutableString * tagName = nil;
	for (int i = 0; i < [self length]; i++) {
		char c = [self characterAtIndex:i];
		if (c == '<') depth += 1;
		else if (c == '>') depth -= 1;
		else if (depth == 0) {
			if (depth == 0 && tagName) {
				if ([[tagName lowercaseString] hasPrefix:@"br"]) {
					[newString appendFormat:@"\n"];
				}
				[tagName release];
				tagName = nil;
			}
			[newString appendFormat:@"%c", c];
		} else {
			if (!tagName) tagName = [[NSMutableString alloc] init];
			[tagName appendFormat:@"%c"];
		}
		if (tagName) {
			if ([[tagName lowercaseString] hasPrefix:@"br"]) {
				[newString appendFormat:@"\n"];
			}
			[tagName release];
			tagName = nil;
		}
	}
	[newString replaceOccurrencesOfString:@"&lt;" withString:@"<"
								  options:NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
	[newString replaceOccurrencesOfString:@"&gt;" withString:@">"
								  options:NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
	[newString replaceOccurrencesOfString:@"&amp;" withString:@"&"
								  options:NSCaseInsensitiveSearch range:NSMakeRange(0, [newString length])];
	return newString;
}
- (NSString *)stringByAddingAOLRTFTags {
	// WIP
	return nil;
}

@end
