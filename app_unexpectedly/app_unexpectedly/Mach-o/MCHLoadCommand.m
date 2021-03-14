
#import "MCHLoadCommand.h"

#import "MCHObjectFile.h"

#import "MCHUUIDLoadCommand.h"
#import "MCHSegmentLoadCommand.h"

/*#import "MTBCRpathLoadCommand.h"
#import "MTBCLinkEditDataLoadCommand.h"
#import "MTBCMinimumVersionLoadCommand.h"
#import "MTBCSourceVersionLoadCommand.h"
#import "MTBCEncryptionLoadCommand.h"

#import "MTBCDynamicLinkerLoadCommand.h"
#import "MTBCDynamicLinkedSharedLibraryLoadCommand.h"
#import "MTBCPreboundDynamicLibraryCommand.h"*/

#include <mach-o/loader.h>

@interface MCHLoadCommand ()

@property uint32_t type;

@end

@implementation MCHLoadCommand

+ (uint32_t)typeFromLoadCommandBuffer:(const char *)inBytes length:(NSUInteger)inLength swap:(BOOL)inSwap
{
	if (inBytes==NULL || inLength<(sizeof(uint32_t)))
        return 0;
    
    uint32_t tCommandType=*((uint32_t *) inBytes);
    
    if (inSwap==YES)
        tCommandType=OSSwapBigToHostInt32(tCommandType);

    return tCommandType;
}

- (id)initWithBytes:(const char *)inBytes length:(NSUInteger)inLength swap:(BOOL)inSwap architecture:(MCHArchitecture)inArchitecture objectFile:(MCHObjectFile *)inObjectFile
{
	if (inBytes==NULL || inLength<=(sizeof(uint32_t)))
        return nil;
    
    uint32_t tCommandType=[MCHLoadCommand typeFromLoadCommandBuffer:inBytes length:inLength swap:inSwap];
    
    uint32_t tCommandSize=*(((uint32_t *) inBytes)+1);
    
    if (inSwap==YES)
        tCommandSize=OSSwapBigToHostInt32(tCommandSize);
    
    switch(tCommandType)
    {
        case LC_SEGMENT:
            
            self=[[MCHSegmentLoadCommand alloc] initWithBytes:inBytes length:tCommandSize swap:inSwap architecture:MCHArchitecture32 objectFile:inObjectFile];
            break;
            
        case LC_SEGMENT_64:
            
            self=[[MCHSegmentLoadCommand alloc] initWithBytes:inBytes length:tCommandSize swap:inSwap architecture:MCHArchitecture64 objectFile:inObjectFile];
            break;
            
        case LC_SYMTAB:
            
            // A COMPLETER
            
            break;
        
        case LC_DYSYMTAB:
            
            // A COMPLETER
            
            break;
            
        case LC_ID_DYLIB:
        case LC_LOAD_DYLIB:
        case LC_LOAD_WEAK_DYLIB:
        case LC_REEXPORT_DYLIB:
            
            break;
            
        case LC_LOAD_DYLINKER:
            
            break;
            
        case LC_PREBOUND_DYLIB:
            
            break;
            
        case LC_UUID:
            
            self=[[MCHUUIDLoadCommand alloc] initWithBytes:inBytes length:tCommandSize swap:inSwap architecture:inArchitecture objectFile:inObjectFile];
            
            break;
        
        case LC_RPATH:
            
            break;
            
        case LC_CODE_SIGNATURE:
        case LC_SEGMENT_SPLIT_INFO:
        case LC_FUNCTION_STARTS:
        case LC_DATA_IN_CODE:
        case LC_DYLIB_CODE_SIGN_DRS:
        case LC_LINKER_OPTIMIZATION_HINT:
            
            break;
            
        case LC_VERSION_MIN_MACOSX:
        case LC_VERSION_MIN_IPHONEOS:
            
            break;
        
        case LC_SOURCE_VERSION:
            
            break;
            
        case LC_ENCRYPTION_INFO:
            
            break;
            
        case LC_ENCRYPTION_INFO_64:
            
            break;
        
        case LC_DYLD_INFO:
        case LC_DYLD_INFO_ONLY:
            
            break;
        
        case LC_BUILD_VERSION:
            
            break;
            
        default:
            
            NSLog(@"Unknow load command type: %d",tCommandType);
            
            return nil;
    }
    
    if (self!=nil)
    {
        _type=tCommandType;
    }
    
    return self;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tMutableString=[NSMutableString string];
	
	[tMutableString appendFormat:@"0x%04x command:\n",self.type];
	[tMutableString appendFormat:@"  size: %u\n",(uint32_t)self.bufferSize];
	
	return [tMutableString copy];
}

@end
