
#import "MCHUUIDLoadCommand.h"

#include <mach-o/loader.h>

@implementation MCHUUIDLoadCommand

- (id)initWithBytes:(const char *)inBytes length:(NSUInteger)inLength swap:(BOOL)inSwap architecture:(MCHArchitecture)inArchitecture objectFile:(MCHObjectFile *)inObjectFile
{
	if (inLength<sizeof(struct uuid_command))
        return nil;
    
    self=[super initWithBytes:inBytes length:inLength swap:inSwap architecture:inArchitecture];
    
    if (self!=nil)
    {
        struct uuid_command * tUUIDCommandPtr=(struct uuid_command *)inBytes;
        
        _uuid=[[NSUUID alloc] initWithUUIDBytes:tUUIDCommandPtr->uuid];
    }
    
    return self;
}

#pragma mark -

- (NSString *)description
{
	NSMutableString * tMutableString=[NSMutableString string];
	
	[tMutableString appendString:@"LC_UUID command:\n"];
	[tMutableString appendFormat:@"  uuid: %@\n",_uuid.UUIDString];
	
	return [tMutableString copy];
}

@end
