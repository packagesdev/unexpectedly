//
//  NoodleLineNumberMarker.m
//  Line View Test
//
//  Created by Paul Kim on 9/30/08.
//  Copyright (c) 2008 Noodlesoft, LLC. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

// Converted to Objective-C 2.x by Stephane Sudre

#import "NoodleLineNumberMarker.h"

NSString * const NOODLE_LINE_CODING_KEY=@"line";

@implementation NoodleLineNumberMarker

- (instancetype)initWithRulerView:(NSRulerView *)inRulerView lineNumber:(NSUInteger)inLineNumber image:(NSImage *)inImage imageOrigin:(NSPoint)inImageOrigin
{
    self = [super initWithRulerView:inRulerView markerLocation:0.0 image:inImage imageOrigin:inImageOrigin];
    
	if (self != nil)
	{
		_lineNumber = inLineNumber;
	}
    
	return self;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    
    if (self != nil)
	{
		if ([decoder allowsKeyedCoding]==YES)
		{
			_lineNumber = [[decoder decodeObjectForKey:NOODLE_LINE_CODING_KEY] unsignedIntegerValue];
		}
		else
		{
			_lineNumber = [[decoder decodeObject] unsignedIntegerValue];
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];
	
	if ([encoder allowsKeyedCoding]==YES)
	{
		[encoder encodeObject:@(self.lineNumber) forKey:NOODLE_LINE_CODING_KEY];
	}
	else
	{
		[encoder encodeObject:@(self.lineNumber)];
	}
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
	NoodleLineNumberMarker * nMarker=[super copyWithZone:zone];
	
    nMarker.lineNumber=self.lineNumber;
    
    return nMarker;
}

@end
