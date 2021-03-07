//
//  MTBCSection.h
//  Mach-in-Truc
//
//  Created by stephane on 5/28/15.
//  Copyright (c) 2015 stephane. All rights reserved.
//

#import "MCHMemoryBufferWrapper.h"

@class MCHObjectFile;

@interface MCHSection : MCHMemoryBufferWrapper

@property (readonly) MCHObjectFile * objectFile;
@property (readonly) NSString *name;
@property (readonly) NSString *segmentName;
@property (readonly) uint64_t address;


- (id)initWithBytes:(const char *)inBytes length:(NSUInteger)inLength swap:(BOOL)inSwap architecture:(MCHArchitecture)inArchitecture objectFile:(MCHObjectFile *)inObjectFile;

- (const char *)bytesAtAddress:(uint64_t)inAddress;

@end
