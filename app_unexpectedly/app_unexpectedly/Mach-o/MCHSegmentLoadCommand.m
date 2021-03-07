//
//  MTBCSegmentLoadCommand.m
//  Mach-in-Truc
//
//  Created by stephane on 6/2/15.
//  Copyright (c) 2015 stephane. All rights reserved.
//

#import "MCHSegmentLoadCommand.h"

#include <mach-o/loader.h>

#import "MCHObjectFile.h"

@interface MCHSegmentLoadCommand ()
{
	NSMutableArray *_sectionsArray;
}

@end

@implementation MCHSegmentLoadCommand

- (id)initWithBytes:(const char *)inBytes length:(NSUInteger)inLength swap:(BOOL)inSwap architecture:(MCHArchitecture)inArchitecture objectFile:(MCHObjectFile *)inObjectFile
{
	if (inLength>=sizeof(struct segment_command))
	{
		self=[super initWithBytes:inBytes length:inLength swap:inSwap architecture:inArchitecture];
		
		if (self!=nil)
		{
			NSString * tSegmentName=nil;
			MCHMemoryBufferWrapper * tMemoryBufferWrapper=nil;
			uint32_t tFlags=0;
			uint32_t tNumberOfSections=0;
			const char * tReadBuffer=NULL;
		
			if (inArchitecture==MCHArchitecture32)
			{
				struct segment_command * tSegmentCommand32Ptr=(struct segment_command *)inBytes;
				
				tSegmentName=[[NSString alloc] initWithCString:tSegmentCommand32Ptr->segname
													  encoding:NSASCIIStringEncoding];
				
				uint32_t tOffset=tSegmentCommand32Ptr->fileoff;
				if (self.shouldSwap==YES)
					tOffset=OSSwapBigToHostInt32(tOffset);
				
				uint32_t tSize=tSegmentCommand32Ptr->filesize;
				if (self.shouldSwap==YES)
					tSize=OSSwapBigToHostInt32(tSize);
				
				tFlags=tSegmentCommand32Ptr->flags;
				if (self.shouldSwap==YES)
					tFlags=OSSwapBigToHostInt32(tFlags);
				
				tNumberOfSections=tSegmentCommand32Ptr->nsects;
				if (self.shouldSwap==YES)
					tNumberOfSections=OSSwapBigToHostInt32(tNumberOfSections);
				
				tReadBuffer=inBytes+sizeof(struct segment_command);
				
				tMemoryBufferWrapper=[[MCHMemoryBufferWrapper alloc] initWithBytes:inObjectFile.buffer+tOffset length:tSize swap:inSwap architecture:inArchitecture];
			}
			else if (inArchitecture==MCHArchitecture64)
			{
				struct segment_command_64 * tSegmentCommand64Ptr=(struct segment_command_64 *)inBytes;
				
				tSegmentName=[[NSString alloc] initWithCString:tSegmentCommand64Ptr->segname
													  encoding:NSASCIIStringEncoding];
				
				uint64_t tOffset=tSegmentCommand64Ptr->fileoff;
				if (self.shouldSwap==YES)
					tOffset=OSSwapBigToHostInt64(tOffset);
				
				uint64_t tSize=tSegmentCommand64Ptr->filesize;
				if (self.shouldSwap==YES)
					tSize=OSSwapBigToHostInt64(tSize);
				
				tFlags=tSegmentCommand64Ptr->flags;
				if (self.shouldSwap==YES)
					tFlags=OSSwapBigToHostInt32(tFlags);
				
				tNumberOfSections=tSegmentCommand64Ptr->nsects;
				if (self.shouldSwap==YES)
					tNumberOfSections=OSSwapBigToHostInt32(tNumberOfSections);
				
				tMemoryBufferWrapper=[[MCHMemoryBufferWrapper alloc] initWithBytes:inObjectFile.buffer+tOffset length:tSize swap:inSwap architecture:inArchitecture];
				
				tReadBuffer=inBytes+sizeof(struct segment_command_64);
			}
			else
			{
				// Unknown architecture
				
				return nil;
			}
			
			_flags=tFlags;
			
			NSMutableArray * tMutableArray=[NSMutableArray array];
			
			if (tNumberOfSections>0)
			{
				for(uint32_t tSectionIndex=0;tSectionIndex<tNumberOfSections;tSectionIndex++)
				{
					id tSegmentSection;
					
					if (inArchitecture==MCHArchitecture32)
					{
						tSegmentSection=[[MCHSection alloc] initWithBytes:tReadBuffer
																	length:sizeof(struct section)
																	  swap:self.shouldSwap
																 architecture:inArchitecture
																objectFile:(MCHObjectFile *)inObjectFile];
						
						tReadBuffer+=sizeof(struct section);
					}
					else if (inArchitecture==MCHArchitecture64)
					{
						tSegmentSection=[[MCHSection alloc] initWithBytes:tReadBuffer
																	length:sizeof(struct section_64)
																		 swap:self.shouldSwap
																 architecture:inArchitecture
																objectFile:(MCHObjectFile *)inObjectFile];
						
						tReadBuffer+=sizeof(struct section_64);
					}
					
					if (tSegmentSection!=nil)
						[tMutableArray addObject:tSegmentSection];
				}
			}
			
			_segment=[[MCHSegment alloc] initWithName:tSegmentName sections:[tMutableArray copy] memoryBufferWrapper:tMemoryBufferWrapper];
			
			return self;
		}
	}
	
	return nil;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tMutableString=[NSMutableString string];
	
	NSString * tCmdName=@"unknown";
	
	switch(self.type)
	{
		case LC_SEGMENT:
			
			tCmdName=@"LC_SEGMENT";
			break;
			
		case LC_SEGMENT_64:
			
			tCmdName=@"LC_SEGMENT_64";
			break;
	}
	
	[tMutableString appendFormat:@"%@ command:\n",tCmdName];
	[tMutableString appendFormat:@"  flags: 0x%08x\n",self.flags];
	[tMutableString appendFormat:@"  segment name: %@\n",_segment.name];
	[tMutableString appendFormat:@"  number of sections: %u\n",(uint32_t)_segment.allSections.count];
	
	[[_segment allSections] enumerateObjectsUsingBlock:^(MCHSection * bSegmentSection, NSUInteger bIndex, BOOL * bOutStop){
		
		[tMutableString appendString:[bSegmentSection description]];
		[tMutableString appendString:@"\n"];
	}];
	
	return [tMutableString copy];
}

@end
