/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "MCHMachBinary.h"

#include <mach-o/loader.h>
#include <mach-o/fat.h>

@interface MCHMachBinary ()
{
	NSMutableArray * _objectFilesArray;
	
    NSData * _cachedData;
    
	NSUInteger bufferSize;
	const char * buffer;
}

@end

@implementation MCHMachBinary

- (instancetype)initWithContentsOfFile:(NSString *)inPath
{
	if (inPath!=nil)
	{
		_cachedData=[NSData dataWithContentsOfFile:inPath];
	
		if (_cachedData!=nil)
			return [self initWithBytes:_cachedData.bytes length:_cachedData.length swap:NO];
	}
	
	return nil;
}

- (instancetype)initWithContentsOfURL:(NSURL *)inURL
{
	if (inURL!=nil)
	{
		NSData * _cachedData=[NSData dataWithContentsOfURL:inURL];
		
		if (_cachedData!=nil)
			return [self initWithBytes:_cachedData.bytes length:_cachedData.length swap:NO];
	}
	
	return nil;
}

- (id)initWithBytes:(const char *)inBytes length:(NSUInteger)inLength swap:(BOOL)inSwap
{
	self=[super initWithBytes:inBytes length:inLength swap:inSwap];
	
	if (self!=nil)
	{
		NSUInteger tFutureBufferOffset=0;
	
		tFutureBufferOffset+=sizeof(uint32_t);
			
		if (tFutureBufferOffset>=self.bufferSize)
		{
			// Buffer too small
			
			// A COMPLETER
			
			goto init_bail;
		}
			
		// Determine the architecture
		
		uint32_t tMagicNumber=*((uint32_t *)self.buffer);
		
		BOOL tSwap=YES;
		
		switch(tMagicNumber)
		{
			case MH_MAGIC:
			case MH_CIGAM:
			case MH_MAGIC_64:
			case MH_CIGAM_64:
			{
				MCHObjectFile * tObjectFile=[[MCHObjectFile alloc] initWithBytes:self.buffer
																			length:self.bufferSize];
				
				if (tObjectFile==nil)
				{
					goto init_bail;
				}
				
				_objectFilesArray=[NSMutableArray arrayWithObject:tObjectFile];
				
				break;
			}
				
			case FAT_MAGIC:
				
				tSwap=NO;
				
			case FAT_CIGAM:		// FAT
			{
				tFutureBufferOffset+=sizeof(uint32_t);
				
				if (tFutureBufferOffset>=self.bufferSize)
				{
					// A COMPLETER
					
					goto init_bail;
				}
				
				_objectFilesArray=[NSMutableArray array];
				
				struct fat_header * tFatHeaderPtr=(struct fat_header *)self.buffer;
				uint32_t tArchitecturesCount=tFatHeaderPtr->nfat_arch;
				
				if (tSwap==YES)
					tArchitecturesCount=OSSwapBigToHostInt32(tArchitecturesCount);
				
				const char * tReadBuffer=self.buffer+tFutureBufferOffset;
				
				for(uint32_t tIndex=0;tIndex<tArchitecturesCount;tIndex++)
				{
					tFutureBufferOffset+=sizeof(struct fat_arch);
					
					if (tFutureBufferOffset>=self.bufferSize)
					{
						// A COMPLETER
						
						goto init_bail;
					}
					
					struct fat_arch * tFatArchPtr=(struct fat_arch *)tReadBuffer;
					
					MCHObjectFile * tObjectFile;
					
					if (tSwap==YES)
						tObjectFile=[[MCHObjectFile alloc] initWithBytes:self.buffer+OSSwapBigToHostInt32(tFatArchPtr->offset)
																   length:OSSwapBigToHostInt32(tFatArchPtr->size)];
					else
						tObjectFile=[[MCHObjectFile alloc] initWithBytes:self.buffer+tFatArchPtr->offset
																   length:tFatArchPtr->size];
						
					if (tObjectFile==nil)
					{
						goto init_bail;
					}
					
					[_objectFilesArray addObject:tObjectFile];
					
					tReadBuffer+=sizeof(struct fat_arch);
				}
				
				break;
			}
			default:
				
				NSLog(@"Unknown Mach Binary format");
				
				// A COMPLETER
				
				goto init_bail;
		}
		
		return self;
	}

init_bail:
	
	return nil;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tMutableString=[NSMutableString string];
	
	if (self.isFatBinary==YES)
		[tMutableString appendFormat:@"FAT binary (%d object files)\n",(int)[self allObjectFiles].count];
	
	[[self allObjectFiles] enumerateObjectsUsingBlock:^(MCHObjectFile * bObjectFile,NSUInteger bIndex,BOOL * bOutStop){
		
		[tMutableString appendString:[bObjectFile description]];
	}];
	
	return [tMutableString copy];
}

#pragma mark -

- (BOOL)isFatBinary
{
	return (_objectFilesArray.count>1);
}

#pragma mark -

- (NSArray *)allObjectFiles
{
	return _objectFilesArray;
}

@end
