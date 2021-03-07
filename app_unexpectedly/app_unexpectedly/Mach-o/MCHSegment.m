//
//  MTBCSegment.m
//  Mach-in-Truc
//
//  Created by stephane on 6/6/15.
//  Copyright (c) 2015 stephane. All rights reserved.
//

#import "MCHSegment.h"

@interface MCHSegment ()
{
	NSArray * _sections;
	NSDictionary *_sectionsIndex;
}

@end

@implementation MCHSegment

- (id)initWithName:(NSString *)inName sections:(NSArray *)inSections memoryBufferWrapper:(MCHMemoryBufferWrapper *)inMemoryBufferWrapper
{
	self=[super initWithBytes:inMemoryBufferWrapper.buffer length:inMemoryBufferWrapper.bufferSize swap:inMemoryBufferWrapper.shouldSwap architecture:inMemoryBufferWrapper.architecture];
	
	if (self!=nil)
	{
		_name=inName;
		
		_sections=inSections;
		
		NSMutableDictionary * tMutableDictionary=[NSMutableDictionary dictionary];
		
		[_sections enumerateObjectsUsingBlock:^(MCHSection * bSection, NSUInteger bIndex, BOOL * bOutStop){
		
			if (bSection.name!=nil)
				tMutableDictionary[bSection.name]=bSection;
		
		}];
		
		_sectionsIndex=[tMutableDictionary copy];
	}
	
	return self;
}

#pragma mark -

- (NSUInteger)hash
{
    return self.name.hash;
}

- (NSString *)description
{
	return @"Description forthcoming";
}

#pragma mark -

- (NSArray *)allSections
{
	return _sections;
}

- (MCHSection *)sectionNamed:(NSString *)inName
{
	return _sectionsIndex[inName];
}

@end
