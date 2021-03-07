
#import "MCHMemoryBufferWrapper.h"

@class MCHObjectFile;

@interface MCHLoadCommand : MCHMemoryBufferWrapper

@property (readonly) uint32_t type;

+ (uint32_t)typeFromLoadCommandBuffer:(const char *)inBytes length:(NSUInteger)inLength swap:(BOOL)inSwap;

- (id)initWithBytes:(const char *)inBytes length:(NSUInteger)inLength swap:(BOOL)inSwap architecture:(MCHArchitecture)inArchitecture objectFile:(MCHObjectFile *)inObjectFile;

@end
