/*
 Copyright (c) 2020-2023, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
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
