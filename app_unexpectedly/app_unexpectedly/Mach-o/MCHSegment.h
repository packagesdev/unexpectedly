
#import "MCHMemoryBufferWrapper.h"

#import "MCHSection.h"

@interface MCHSegment : MCHMemoryBufferWrapper

@property (readonly) NSString * name;

- (id)initWithName:(NSString *)inName sections:(NSArray *)inSections memoryBufferWrapper:(MCHMemoryBufferWrapper *)inMemoryBufferWrapper;

@property (nonatomic,readonly) NSArray * allSections;

- (MCHSection *)sectionNamed:(NSString *)inName;

@end
