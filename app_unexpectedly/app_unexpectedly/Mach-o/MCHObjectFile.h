//
//  MTBCArchitectureObjectFile.h
//  Mach-in-Truc
//
//  Created by stephane on 5/28/15.
//  Copyright (c) 2015 stephane. All rights reserved.
//

#import "MCHMemoryBufferWrapper.h"

#import "MCHLoadCommand.h"
#import "MCHSegment.h"

#include <mach-o/loader.h>

@interface MCHObjectFile : MCHMemoryBufferWrapper

@property (readonly) cpu_type_t cpuType;
@property (readonly) cpu_subtype_t cpuSubType;
@property (readonly) uint32_t fileType;
@property (readonly) uint32_t flags;

@property (nonatomic,readonly) NSArray<MCHLoadCommand *> * allLoadCommands;

- (NSArray<MCHLoadCommand *> *)loadCommandsOfType:(uint32_t)inType;

@property (nonatomic,readonly) NSArray * allSegments;

- (MCHSegment *)segmentNamed:(NSString *)inName;
//- (MTBCSegment *)segmentAtAddress:(uint64_t)inAddress;

@end
