
#import "MCHSection.h"

#import "MCHObjectFile.h"

#include <mach-o/loader.h>

/*#import "MTBCCStringSection.h"
#import "MTBCCFStringSection.h"


#import "MTBCOBJC1ModuleInfoSection.h"
#import "MTBCOBJC1SymbolsSection.h"
#import "MTBCOBJC1ClassSection.h"
#import "MTBCOBJC1CategorySection.h"

#import "MTBCOBJC2ClassListSection.h"
#import "MTBCOBJC2ObjcDataSection.h"*/

@implementation MCHSection

- (id)initWithBytes:(const char *)inBytes length:(NSUInteger)inLength swap:(BOOL)inSwap architecture:(MCHArchitecture)inArchitecture objectFile:( MCHObjectFile *)inObjectFile;
{
	if (inBytes==NULL)
        return nil;

    NSString * tSectionName=nil;
    NSString * tSegmentName=nil;
    uint32_t tOffset=0;
    uint64_t tSize=0;
    uint32_t tFlags=0;
    uint64_t tAddress=0;
    
    if (inArchitecture==MCHArchitecture32)
    {
        struct section * tSection32Ptr=(struct section *)inBytes;
        char cStringBuffer[17];
        
        memset(cStringBuffer,0,17);
        memcpy(cStringBuffer,tSection32Ptr->sectname,16);
        
        tSectionName=[[NSString alloc] initWithCString:cStringBuffer
                                              encoding:NSASCIIStringEncoding];
        
        memset(cStringBuffer,0,17);
        memcpy(cStringBuffer,tSection32Ptr->segname,16);
        
        tSegmentName=[[NSString alloc] initWithCString:cStringBuffer
                                            encoding:NSASCIIStringEncoding];
        
        uint32_t tAddress32=tSection32Ptr->addr;
        
        if (inSwap==YES)
            tAddress32=OSSwapBigToHostInt32(tAddress32);
        
        tAddress=tAddress32;
        
        uint32_t tSize32=tSection32Ptr->size;
        
        if (inSwap==YES)
            tSize32=OSSwapBigToHostInt32(tSize32);
        
        tSize=tSize32;
        
        tOffset=tSection32Ptr->offset;
        
        if (inSwap==YES)
            tOffset=OSSwapBigToHostInt32(tOffset);
        
        tFlags=tSection32Ptr->flags;
        
        if (inSwap==YES)
            tFlags=OSSwapBigToHostInt32(tFlags);
    }
    else if (inArchitecture==MCHArchitecture64)
    {
        struct section_64 * tSection64Ptr=(struct section_64 *)inBytes;
        
        char cStringBuffer[17];
        
        memset(cStringBuffer,0,17);
        memcpy(cStringBuffer,tSection64Ptr->sectname,16);
        
        tSectionName=[[NSString alloc] initWithCString:cStringBuffer
                                              encoding:NSASCIIStringEncoding];
        
        memset(cStringBuffer,0,17);
        memcpy(cStringBuffer,tSection64Ptr->segname,16);
        
        tSegmentName=[[NSString alloc] initWithCString:cStringBuffer
                                              encoding:NSASCIIStringEncoding];
        
        uint64_t tAddress64=tSection64Ptr->addr;
        
        if (inSwap==YES)
            tAddress64=OSSwapBigToHostInt64(tAddress64);
        
        tAddress=tAddress64;
        
        uint64_t tSize64=tSection64Ptr->size;
        
        if (inSwap==YES)
            tSize64=OSSwapBigToHostInt64(tSize64);
        
        tSize=tSize64;
        
        tOffset=tSection64Ptr->offset;
        
        if (inSwap==YES)
            tOffset=OSSwapBigToHostInt32(tOffset);
        
        tFlags=tSection64Ptr->flags;
        
        if (inSwap==YES)
            tFlags=OSSwapBigToHostInt32(tFlags);
    }
    else
    {
        // Unknown architecture
        
        return nil;
    }
    
    uint32_t tType=tFlags&SECTION_TYPE;
    
    id tSection=nil;
    
    switch (tType)
    {
        case S_CSTRING_LITERALS:
            
            /*tSection=[[MTBCCStringSection alloc] initWithBytes:inObjectFile.buffer+tOffset length:(NSUInteger)tSize swap:inSwap architecture:inArchitecture objectFile:inObjectFile];*/
            
            break;
            
        case S_ZEROFILL:
            
            
            
            break;
    
        default:
    
            if ([tSegmentName isEqualToString:@SEG_TEXT]==YES)
            {
                //__objc_classname__TEXT
            }
            else if ([tSegmentName isEqualToString:@SEG_DATA]==YES)
            {
                /*if ([tSectionName isEqualToString:@"__cfstring"]==YES)
                    tSection=[[MTBCCFStringSection alloc] initWithBytes:inObjectFile.buffer+tOffset length:(NSUInteger)tSize swap:inSwap architecture:inArchitecture objectFile:inObjectFile];
                else if ([tSectionName isEqualToString:@"__objc_classlist"]==YES)
                    tSection=[[MTBCOBJC2ClassListSection alloc] initWithBytes:inObjectFile.buffer+tOffset length:(NSUInteger)tSize swap:inSwap architecture:inArchitecture objectFile:inObjectFile];
                else if ([tSectionName isEqualToString:@"__objc_data"]==YES)
                    tSection=[[MTBCOBJC2ObjcDataSection alloc] initWithBytes:inObjectFile.buffer+tOffset length:(NSUInteger)tSize swap:inSwap architecture:inArchitecture objectFile:inObjectFile];*/
                
                
                
                
                // A COMPLETER
            }
            else if ([tSegmentName isEqualToString:@SEG_OBJC]==YES)
            {
                /*if ([tSectionName isEqualToString:@"__module_info"]==YES)
                    tSection=[[MTBCOBJC1ModuleInfoSection alloc] initWithBytes:inObjectFile.buffer+tOffset length:(NSUInteger)tSize swap:inSwap architecture:inArchitecture objectFile:inObjectFile];
                else if ([tSectionName isEqualToString:@"__symbols"]==YES)
                        tSection=[[MTBCOBJC1SymbolsSection alloc] initWithBytes:inObjectFile.buffer+tOffset length:(NSUInteger)tSize swap:inSwap architecture:inArchitecture objectFile:inObjectFile];
                else if ([tSectionName isEqualToString:@"__class"]==YES)
                    tSection=[[MTBCOBJC1ClassSection alloc] initWithBytes:inObjectFile.buffer+tOffset length:(NSUInteger)tSize swap:inSwap architecture:inArchitecture objectFile:inObjectFile];
                else  if ([tSectionName isEqualToString:@"__category"]==YES)
                    tSection=[[MTBCOBJC1CategorySection alloc] initWithBytes:inObjectFile.buffer+tOffset length:(NSUInteger)tSize swap:inSwap architecture:inArchitecture objectFile:inObjectFile];*/
                
                
                
                
                // A COMPLETER
            }
            
            if (tSection==nil)
                tSection=[super initWithBytes:inObjectFile.buffer+tOffset length:(NSUInteger)tSize swap:inSwap architecture:inArchitecture];
            
            break;
    }
    
    self=tSection;
    
    if (self!=nil)
    {
        _objectFile=inObjectFile;
        
        _name=tSectionName;
        _segmentName=tSegmentName;
        _address=tAddress;
    }
    
    return self;
}

- (void)dealloc
{
	_objectFile=nil;
}

#pragma mark -

- (NSUInteger)hash
{
    return self.name.hash;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"    <0x%08llx> (%@,%@)\n",_address,_segmentName,_name];
}

#pragma mark -

- (const char *)bytesAtAddress:(uint64_t)inAddress
{
	return self.buffer+(inAddress-self.address);
}

@end
