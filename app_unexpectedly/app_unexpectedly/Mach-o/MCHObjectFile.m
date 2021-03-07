
#import "MCHObjectFile.h"

#import "MCHSegmentLoadCommand.h"

@interface MCHObjectFile ()
{
	NSMutableArray *_loadCommandsArray;
	
	NSMutableArray *_segmentsArray;
	NSMutableDictionary * _segmentsIndex;
}

@property cpu_type_t cpuType;
@property cpu_subtype_t cpuSubType;
@property uint32_t fileType;
@property uint32_t flags;

@end

@implementation MCHObjectFile

- (instancetype)initWithBytes:(const char *)inBytes length:(NSUInteger)inLength swap:(BOOL)inSwap architecture:(MCHArchitecture)inArchitecture
{
	self=[super initWithBytes:inBytes length:inLength swap:inSwap architecture:inArchitecture];
	
	if (self!=nil)
	{
		NSUInteger tFutureBufferOffset=0;
		
		uint32_t tLoadCommandsNumber;
		//uint32_t tLoadCommandsTotalSize;
		
		if (inArchitecture==MCHArchitecture32)
		{
			if (self.bufferSize<sizeof(struct mach_header))
			{
				// Buffer not big enough
				
				return nil;
			}
			
			struct mach_header * tMach32HeaderPtr=(struct mach_header *)self.buffer;
			
			_cpuType=tMach32HeaderPtr->cputype;
			
			if (self.shouldSwap==YES)
				_cpuType=OSSwapBigToHostInt32(_cpuType);
			
			_cpuSubType=tMach32HeaderPtr->cpusubtype;
			
			if (self.shouldSwap==YES)
				_cpuSubType=OSSwapBigToHostInt32(_cpuSubType);
			
			_fileType=tMach32HeaderPtr->filetype;
			
			if (self.shouldSwap==YES)
				_fileType=OSSwapBigToHostInt32(_fileType);
			
			_flags=tMach32HeaderPtr->flags;
			
			if (self.shouldSwap==YES)
				_flags=OSSwapBigToHostInt32(_flags);
			
			tLoadCommandsNumber=tMach32HeaderPtr->ncmds;
			
			if (self.shouldSwap==YES)
				tLoadCommandsNumber=OSSwapBigToHostInt32(tLoadCommandsNumber);
			
			/*tLoadCommandsTotalSize=tMach32HeaderPtr->sizeofcmds;
			
			if (self.shouldSwap==YES)
				tLoadCommandsTotalSize=OSSwapBigToHostInt32(tLoadCommandsTotalSize);*/
			
			tFutureBufferOffset=sizeof(struct mach_header);
		}
		else if (inArchitecture==MCHArchitecture64)
		{
			if (self.bufferSize<sizeof(struct mach_header_64))
			{
				// Buffer not big enough
				
				return nil;
			}
			
			struct mach_header_64 * tMach64HeaderPtr=(struct mach_header_64 *)self.buffer;
			
			_cpuType=tMach64HeaderPtr->cputype;
			
			if (self.shouldSwap==YES)
				_cpuType=OSSwapBigToHostInt32(_cpuType);
			
			_cpuSubType=tMach64HeaderPtr->cpusubtype;
			
			if (self.shouldSwap==YES)
				_cpuSubType=OSSwapBigToHostInt32(_cpuSubType);
			
			_fileType=tMach64HeaderPtr->filetype;
			
			if (self.shouldSwap==YES)
				_fileType=OSSwapBigToHostInt32(_fileType);
			
			_flags=tMach64HeaderPtr->flags;
			
			if (self.shouldSwap==YES)
				_flags=OSSwapBigToHostInt32(_flags);
			
			tLoadCommandsNumber=tMach64HeaderPtr->ncmds;
			
			if (self.shouldSwap==YES)
				tLoadCommandsNumber=OSSwapBigToHostInt32(tLoadCommandsNumber);
			
			/*tLoadCommandsTotalSize=tMach64HeaderPtr->sizeofcmds;
			
			if (self.shouldSwap==YES)
				tLoadCommandsTotalSize=OSSwapBigToHostInt32(tLoadCommandsTotalSize);*/
			
			tFutureBufferOffset=sizeof(struct mach_header_64);
		}
		else
		{
			// Unknow architecture
			
			return nil;
		}
		
		if (tLoadCommandsNumber>0)
		{
			_loadCommandsArray=[NSMutableArray array];
			
			_segmentsArray=[NSMutableArray array];
			
			_segmentsIndex=[NSMutableDictionary dictionary];
			
			for(uint32_t tLoadCommandIndex=0;tLoadCommandIndex<tLoadCommandsNumber;tLoadCommandIndex++)
			{
				tFutureBufferOffset+=sizeof(struct load_command);
				
				if (tFutureBufferOffset>=self.bufferSize)
				{
					// Buffer too small
					
					return nil;
				}
				
				tFutureBufferOffset-=sizeof(struct load_command);
				
				struct load_command * tLoadCommandPtr=(struct load_command *)(self.buffer+tFutureBufferOffset);
				
				uint32_t tLoadCommandType=tLoadCommandPtr->cmd;
				
				if (self.shouldSwap==YES)
					tLoadCommandType=OSSwapBigToHostInt32(tLoadCommandType);
				
				uint32_t tLoadCommandSize=tLoadCommandPtr->cmdsize;
				
				if (self.shouldSwap==YES)
					tLoadCommandSize=OSSwapBigToHostInt32(tLoadCommandSize);
				
				switch(tLoadCommandType)
				{
					case LC_SEGMENT:
					case LC_SYMTAB:
					case LC_SYMSEG:
					case LC_THREAD:
					case LC_UNIXTHREAD:
					case LC_LOADFVMLIB:
					case LC_IDFVMLIB:
					case LC_IDENT:
					case LC_FVMFILE:
					case LC_PREPAGE:
					case LC_DYSYMTAB:
					case LC_LOAD_DYLIB:
					case LC_ID_DYLIB:
					case LC_LOAD_DYLINKER:
					case LC_ID_DYLINKER:
					case LC_PREBOUND_DYLIB:
					case LC_ROUTINES:
					case LC_SUB_FRAMEWORK:
					case LC_SUB_UMBRELLA:
					case LC_SUB_CLIENT:
					case LC_SUB_LIBRARY:
					case LC_TWOLEVEL_HINTS:
					case LC_PREBIND_CKSUM:
					case LC_LOAD_WEAK_DYLIB:
						
					case LC_SEGMENT_64:
					case LC_ROUTINES_64:
					case LC_UUID:
					case LC_RPATH:
					case LC_CODE_SIGNATURE:
					case LC_SEGMENT_SPLIT_INFO:
					case LC_REEXPORT_DYLIB:
					case LC_LAZY_LOAD_DYLIB:
					case LC_ENCRYPTION_INFO:
					case LC_DYLD_INFO:
					case LC_DYLD_INFO_ONLY:
					case LC_LOAD_UPWARD_DYLIB:
					case LC_VERSION_MIN_MACOSX:
					case LC_VERSION_MIN_IPHONEOS:
					case LC_FUNCTION_STARTS:
					case LC_DYLD_ENVIRONMENT:
					case LC_MAIN:
					case LC_DATA_IN_CODE:
					case LC_SOURCE_VERSION:
					case LC_DYLIB_CODE_SIGN_DRS:
					case LC_ENCRYPTION_INFO_64:
					case LC_LINKER_OPTION:
					case LC_LINKER_OPTIMIZATION_HINT:
                    case LC_BUILD_VERSION:
					{
						MCHLoadCommand * tLoadCommand=[[MCHLoadCommand alloc] initWithBytes:self.buffer+tFutureBufferOffset
																					   length:tLoadCommandSize
																						 swap:self.shouldSwap
																				 architecture:self.architecture
																				   objectFile:self];
						
						if (tLoadCommand!=nil)
						{
							[_loadCommandsArray addObject:tLoadCommand];
							
							if (tLoadCommandType==LC_SEGMENT || tLoadCommandType==LC_SEGMENT_64)
							{
								MCHSegmentLoadCommand * tSegmentLoadCommand=(MCHSegmentLoadCommand *)tLoadCommand;
								
								MCHSegment * tSegment=tSegmentLoadCommand.segment;
								
								if (tSegment!=nil)
								{
									[_segmentsArray addObject:tSegment];
									
									if (tSegment.name!=nil)
										[_segmentsIndex setObject:tSegment forKey:tSegment.name];
								}
							}
						}
						else
						{
							NSLog(@"Error initialization load command 0x%04x (0x%08x,%u)",tLoadCommandType,(uint32_t)tFutureBufferOffset,(uint32_t)tLoadCommandSize);
						}
						
						tFutureBufferOffset+=tLoadCommandSize;
						
						break;
					}
						
					default:
						
						// Unknown load command
						
						NSLog(@"Unknow load command: %d",tLoadCommandType);
						
						tFutureBufferOffset+=tLoadCommandSize;
						
						break;
				}
			}
		}
	}
	
	return self;
}

- (instancetype)initWithBytes:(const char *)inBytes length:(NSUInteger)inLength
{
	if (inBytes!=nil && inLength>sizeof(uint32_t))
	{
		uint32_t tMagicNumber=*((uint32_t *)inBytes);
		
		switch(tMagicNumber)
		{
			case MH_MAGIC:
				
				return [self initWithBytes:inBytes length:inLength swap:NO architecture:MCHArchitecture32];
				
			case MH_CIGAM:
				
				return [self initWithBytes:inBytes length:inLength swap:YES architecture:MCHArchitecture32];
				
			case MH_MAGIC_64:
				
				return [self initWithBytes:inBytes length:inLength swap:NO architecture:MCHArchitecture64];
				
			case MH_CIGAM_64:
				
				return [self initWithBytes:inBytes length:inLength swap:NO architecture:MCHArchitecture64];
				
			default:
		
				// Unknown architecture
				
				break;
		}
	}
	
	return nil;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tMutableString=[NSMutableString string];
	
	[tMutableString appendFormat:@"mach-o file (%@)\n",(self.architecture==MCHArchitecture32)? @"32-bit" : @"64-bit"];
	
	NSString * tFileType=nil;
	
	switch(self.fileType)
	{
		case MH_OBJECT:
			tFileType=@"Object File";
			break;
		case MH_EXECUTE:
			tFileType=@"Executable";
			break;
		case MH_FVMLIB:
			tFileType=@"VM Shared Library File";
			break;
		case MH_CORE:
			tFileType=@"Core File";
			break;
		case MH_PRELOAD:
			tFileType=@"Preloaded Executable";
			break;
		case MH_DYLIB:
			tFileType=@"Dynamic Shared Library";
			break;
		case MH_BUNDLE:
			tFileType=@"Dynamically Bound Bundle File";
			break;
            
        case MH_DSYM:
            
            tFileType=@"Companion file with only debug sections";
            break;
            
		default:
			
			tFileType=@"Description forthcoming";
			break;
	}
	
	[tMutableString appendFormat:@"type: %@\n",tFileType];
	
	NSString * tCPUType=nil;
	
	switch(self.cpuType)
	{
		case CPU_TYPE_I386:
			tCPUType=@"i386";
			break;
		case CPU_TYPE_X86_64:
			tCPUType=@"x86_64";
			break;
		case CPU_TYPE_POWERPC:
			tCPUType=@"ppc";
			break;
		case CPU_TYPE_POWERPC64:
			tCPUType=@"ppc64";
			break;
		case CPU_TYPE_ARM:
			tCPUType=@"arm";
			break;
		case CPU_TYPE_ARM64:
			tCPUType=@"arm64";
			break;
		default:
			
			tCPUType=@"Unknown";
			break;
	}
	
	[tMutableString appendFormat:@"CPU: %@\n",tCPUType];
	
	[tMutableString appendFormat:@"%d load commands:\n",(int) self.allLoadCommands.count];
	
	[self.allLoadCommands enumerateObjectsUsingBlock:^(MCHLoadCommand * bLoadCommand, NSUInteger bIndex, BOOL * bOutStop){
	
		[tMutableString appendString:[bLoadCommand description]];
		[tMutableString appendString:@"\n"];
	}];
	
	[tMutableString appendString:@"\n"];
	
	return [tMutableString copy];
}

#pragma mark -

- (NSArray *)allLoadCommands
{
	return _loadCommandsArray;
}

- (NSArray *)loadCommandsOfType:(uint32_t)inType
{
    NSMutableArray * tMutableArray=[NSMutableArray array];
    
    for( MCHLoadCommand * tLoadCommand in self.allLoadCommands)
    {
        if (tLoadCommand.type==inType)
            [tMutableArray addObject:tLoadCommand];
    }
    
	return [tMutableArray copy];
}

#pragma mark -

- (NSArray *)allSegments
{
	return _segmentsArray;
}

- (MCHSegment *)segmentNamed:(NSString *)inName
{
	if (inName!=nil)
		return [_segmentsIndex objectForKey:inName];

	return nil;
}

@end
