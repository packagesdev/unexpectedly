
#import "MCHLoadCommand.h"

#import "MCHSegment.h"

@interface MCHSegmentLoadCommand : MCHLoadCommand

@property (readonly) MCHSegment * segment;

@property (readonly) uint32_t flags;

@end
