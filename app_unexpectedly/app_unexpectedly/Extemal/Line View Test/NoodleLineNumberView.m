//
//  NoodleLineNumberView.m
//  Line View Test
//
//  Created by Paul Kim on 9/28/08.
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

#import "NoodleLineNumberView.h"
#import "NoodleLineNumberMarker.h"

#define DEFAULT_THICKNESS    22.0
#define RULER_MARGIN        5.0

@interface NoodleLineNumberView ()
{
    NSMutableArray * lineIndices;   // Array of character indices for the beginning of each line
    
    NSMutableDictionary * _linesToMarkers;     // Maps line numbers to markers
}

- (NSMutableArray *)lineIndices;
- (void)invalidateLineIndices;
- (void)calculateLines;
- (NSUInteger)lineNumberForCharacterIndex:(NSUInteger)index inText:(NSString *)text;
- (NSDictionary *)textAttributes;
- (NSDictionary *)markerTextAttributes;

@end

@implementation NoodleLineNumberView

- (id)initWithScrollView:(NSScrollView *)inScrollView
{
    self = [super initWithScrollView:inScrollView orientation:NSVerticalRuler];
    
    if (self != nil)
    {
        _linesToMarkers = [NSMutableDictionary dictionary];
        
        [self setClientView:inScrollView.documentView];
    }
    
    return self;
}

- (void)awakeFromNib
{
    _linesToMarkers = [NSMutableDictionary dictionary];
    
    [self setClientView:self.scrollView.documentView];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (void)setFontSizeDelta:(CGFloat)inFontSizeDelta
{
    if (inFontSizeDelta>0)
    {
        _fontSizeDelta=0;
    }
    else
    {
        if (_fontSizeDelta>-5)
        {
            _fontSizeDelta=inFontSizeDelta;
        }
    }
}

- (NSFont *)font
{
    if (_font == nil)
        return [NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeMini]];
    
    return _font;
}

- (NSColor *)textColor
{
    if (_textColor == nil)
        return [NSColor colorWithCalibratedWhite:0.42 alpha:1.0];

    return _textColor;
}

- (NSColor *)alternateTextColor
{
    if (_alternateTextColor == nil)
        return [NSColor whiteColor];
    
    return _alternateTextColor;
}

#pragma mark -

- (void)setClientView:(NSView *)inClientView
{
    NSNotificationCenter *tNotificationCenter = [NSNotificationCenter defaultCenter];
    
    [tNotificationCenter removeObserver:self name:NSTextStorageDidProcessEditingNotification object:nil];
    
    super.clientView = inClientView;
    
    if ([inClientView isKindOfClass:[NSTextView class]]==YES)
    {
        NSTextStorage *textStorage = ((NSTextView *)inClientView).textStorage;
        
        [tNotificationCenter addObserver:self selector:@selector(clientTextStorageDidProcessEditing:) name:NSTextStorageDidProcessEditingNotification object:textStorage];
        
        [self invalidateLineIndices];
    }
}

- (NSMutableArray *)lineIndices
{
    if (lineIndices == nil)
        [self calculateLines];

    return lineIndices;
}

- (void)invalidateLineIndices
{
    lineIndices = nil;
}

- (NSUInteger)lineNumberForLocation:(CGFloat)inLocation
{
    NSTextView * tTextView = (NSTextView *)self.clientView;
    
    if ([tTextView isKindOfClass:[NSTextView class]]==NO)
    
        return NSNotFound;
    
    NSRect tVisibleRect = [self scrollView].contentView.bounds;
    
    inLocation += NSMinY(tVisibleRect);
    
    NSRange nullRange = NSMakeRange(NSNotFound, 0);
    NSLayoutManager * tLayoutManager = tTextView.layoutManager;
    NSTextContainer * tTextContainter = tTextView.textContainer;
    
    NSMutableArray * tLineIndices = [self lineIndices];
    NSUInteger tCount = tLineIndices.count;
    
    for (NSUInteger tLine = 0; tLine < tCount; tLine++)
    {
        NSUInteger index = [tLineIndices[tLine] unsignedIntValue];
        
        NSUInteger tRectCount;
        NSRectArray tRects = [tLayoutManager rectArrayForCharacterRange:NSMakeRange(index, 0)
                                           withinSelectedCharacterRange:nullRange
                                                        inTextContainer:tTextContainter
                                                              rectCount:&tRectCount];
        
        for (NSUInteger tIndex = 0; tIndex < tRectCount; tIndex++)
        {
            NSRect tRect=tRects[tIndex];
            
            if ((inLocation >= NSMinY(tRect)) && (inLocation < NSMaxY(tRect)))
                return tLine + 1;
        }
    }
    
    return NSNotFound;
}

- (NoodleLineNumberMarker *)markerAtLine:(NSUInteger)inLine
{
    return _linesToMarkers[@(inLine - 1)];
}

- (void)calculateLines
{
    NSTextView * tTextView=(NSTextView *)[self clientView];
    
    if ([tTextView isKindOfClass:[NSTextView class]]==NO)
        return;
    
    NSUInteger lineEnd, contentEnd;
    
    NSString *text = tTextView.string;
    NSUInteger stringLength = text.length;
    
    lineIndices = [NSMutableArray array];
    
    NSUInteger index = 0;
    NSUInteger numberOfLines = 0;
    
    do
    {
        [lineIndices addObject:@(index)];
        
        index = NSMaxRange([text lineRangeForRange:NSMakeRange(index, 0)]);
        numberOfLines++;
    }
    while (index < stringLength);
    
    // Check if text ends with a new line.
    [text getLineStart:NULL end:&lineEnd contentsEnd:&contentEnd forRange:NSMakeRange([lineIndices.lastObject unsignedIntValue], 0)];
    if (contentEnd < lineEnd)
    {
        [lineIndices addObject:@(index)];
    }
    
    CGFloat oldThickness = self.ruleThickness;
    CGFloat newThickness = self.requiredThickness;
    if (fabs(oldThickness - newThickness) > 1)
    {
        /*// Not a good idea to resize the view during calculations (which can happen during
        // display). Do a delayed perform (using NSInvocation since arg is a float).
        
        dispatch_async(dispatch_get_main_queue(), ^{*/
            
            self.ruleThickness=newThickness;
        /*});*/
    }
}

- (NSUInteger)lineNumberForCharacterIndex:(NSUInteger)index inText:(NSString *)text
{
    NSMutableArray * tLineIndices = [self lineIndices];
    
    // Binary search
    NSUInteger left = 0;
    NSUInteger right =  tLineIndices.count;
    
    while ((right - left) > 1)
    {
        NSUInteger mid = (right + left) / 2;
        NSUInteger lineStart = [tLineIndices[mid] unsignedIntValue];
        
        if (index < lineStart)
        {
            right = mid;
        }
        else if (index > lineStart)
        {
            left = mid;
        }
        else
        {
            return mid;
        }
    }
    
    return left;
}

- (NSDictionary *)textAttributes
{
    NSFont * tFont=self.font;
    
    NSFont * tAdjustedFont=nil;
    
    if (_fontSizeDelta<0)
    {
        tAdjustedFont=[[NSFontManager sharedFontManager] convertFont:tFont toSize:tFont.pointSize + _fontSizeDelta];
    }
    
    if (tAdjustedFont==nil)
        tAdjustedFont=tFont;
    
    return @{
             NSFontAttributeName:tAdjustedFont,
             NSForegroundColorAttributeName:self.textColor
             };
}

- (NSDictionary *)markerTextAttributes
{
    return @{
             NSFontAttributeName:self.font,
             NSForegroundColorAttributeName:self.alternateTextColor
             };
}

- (CGFloat)requiredThickness
{
    NSUInteger lineCount = [self lineIndices].count;
    NSUInteger digits = (NSUInteger)log10(lineCount) + 1;
    
    if (digits<4)
        digits=4;
    
    NSMutableString * sampleString = [NSMutableString string];
    for (NSUInteger i = 0; i < digits; i++)
    {
        // Use "8" since it is one of the fatter numbers. Anything but "1"
        // will probably be ok here. I could be pedantic and actually find the fattest
        // number for the current font but nah.
        [sampleString appendString:@"8"];
    }
    
    NSDictionary * tAttributes=@{NSFontAttributeName:self.font};
    
    NSSize stringSize = [sampleString sizeWithAttributes:tAttributes];
    
    // Round up the value. There is a bug on 10.4 where the display gets all wonky when scrolling if you don't
    // return an integral value here.
    return ceilf(MAX(DEFAULT_THICKNESS, stringSize.width + RULER_MARGIN * 2));
}

#pragma mark - Drawing

- (void)viewWillDraw
{
    [super viewWillDraw];
    
    if (lineIndices == nil)
        [self calculateLines];
}

- (void)drawSeparatorInRect:(NSRect)inRect
{
}

- (void)drawHashMarksAndLabelsInRect:(NSRect)aRect
{
    NSRect bounds = [self bounds];
    
    if (self.backgroundColor != nil)
    {
        [self.backgroundColor set];
        NSRectFill(aRect);
    }
    
    NSTextView * tTextView =(NSTextView *) self.clientView;
    
    if ([tTextView isKindOfClass:[NSTextView class]]==NO)
        return;
    
    NSRect                    markerRect;
    NSString                *labelText;
    NSUInteger                line;
    CGFloat                    ypos;
    NSDictionary           *currentTextAttributes;
    
    NSLayoutManager *layoutManager = tTextView.layoutManager;
    NSTextContainer *container = tTextView.textContainer;
    NSString * text = tTextView.string;
    NSRange nullRange = NSMakeRange(NSNotFound, 0);
    
    CGFloat yinset = 6;//[tTextView textContainerInset].height;
    NSRect visibleRect = [self scrollView].contentView.bounds;
    
    NSDictionary * textAttributes = [self textAttributes];
    
    NSMutableArray * lines = [self lineIndices];
    
    // Find the characters that are currently visible
    NSRange glyphRange = [layoutManager glyphRangeForBoundingRect:visibleRect inTextContainer:container];
    NSRange range = [layoutManager characterRangeForGlyphRange:glyphRange actualGlyphRange:NULL];
    
    // Fudge the range a tad in case there is an extra new line at end.
    // It doesn't show up in the glyphs so would not be accounted for.
    range.length++;
    
    NSUInteger count = lines.count;
    NSUInteger index = 0;
    
    for (line = [self lineNumberForCharacterIndex:range.location inText:text]; line < count; line++)
    {
        index = [lines[line] unsignedIntValue];
        
        if (NSLocationInRange(index, range))
        {
            NSUInteger rectCount;
            
            NSRectArray rects = [layoutManager rectArrayForCharacterRange:NSMakeRange(index, 0)
                                 withinSelectedCharacterRange:nullRange
                                              inTextContainer:container
                                                    rectCount:&rectCount];
            
            if (rectCount > 0)
            {
                // Note that the ruler view is only as tall as the visible
                // portion. Need to compensate for the clipview's coordinates.
                ypos = yinset + NSMinY(rects[0]) - NSMinY(visibleRect);
                
                NoodleLineNumberMarker * tMarker = _linesToMarkers[@(line)];
                
                if (tMarker != nil)
                {
                    NSImage * markerImage = tMarker.image;
                    NSSize markerSize = markerImage.size;
                    markerRect = NSMakeRect(0.0, 0.0, markerSize.width, markerSize.height);
                    
                    // Marker is flush right and centered vertically within the line.
                    markerRect.origin.x = NSWidth(bounds) - markerSize.width - 1.0;
                    markerRect.origin.y = ypos + NSHeight(rects[0]) / 2.0 - tMarker.imageOrigin.y;
                    
                    [markerImage drawInRect:markerRect fromRect:NSMakeRect(0, 0, markerSize.width, markerSize.height) operation:NSCompositingOperationSourceOver fraction:1.0];
                }
                
                // Line numbers are internally stored starting at 0
                labelText = [NSString stringWithFormat:@"%lu", line + 1];
                
                NSSize stringSize = [labelText sizeWithAttributes:textAttributes];
                
                if (tMarker == nil)
                {
                    currentTextAttributes = textAttributes;
                }
                else
                {
                    currentTextAttributes = [self markerTextAttributes];
                }
                
                // Draw string flush right, centered vertically within the line
                [labelText drawInRect:NSMakeRect(NSWidth(bounds) - stringSize.width - RULER_MARGIN,ypos + (NSHeight(rects[0]) - stringSize.height) / 2.0,NSWidth(bounds) - RULER_MARGIN * 2.0, NSHeight(rects[0]))
                       withAttributes:currentTextAttributes];
            }
        }
        
        if (index > NSMaxRange(range))
            break;
    }
}

#pragma mark - Markers

- (void)setMarkers:(NSArray *)inMarkers
{
    [_linesToMarkers removeAllObjects];
    
    [super setMarkers:nil];
    
    for(NSRulerMarker * tMarker in inMarkers)
        [self addMarker:tMarker];
}

- (void)addMarker:(NSRulerMarker *)inMarker
{
    if ([inMarker isKindOfClass:[NoodleLineNumberMarker class]]==YES)
    {
        _linesToMarkers[@([(NoodleLineNumberMarker *)inMarker lineNumber] - 1)]=inMarker;
    }
    else
    {
        [super addMarker:inMarker];
    }
}

- (void)removeMarker:(NSRulerMarker *)aMarker
{
    if ([aMarker isKindOfClass:[NoodleLineNumberMarker class]])
    {
        [_linesToMarkers removeObjectForKey:@([(NoodleLineNumberMarker *)aMarker lineNumber] - 1)];
    }
    else
    {
        [super removeMarker:aMarker];
    }
}

#pragma mark - NSCoding

#define NOODLE_FONT_CODING_KEY                @"font"
#define NOODLE_TEXT_COLOR_CODING_KEY        @"textColor"
#define NOODLE_ALT_TEXT_COLOR_CODING_KEY    @"alternateTextColor"
#define NOODLE_BACKGROUND_COLOR_CODING_KEY    @"backgroundColor"

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder]) != nil)
    {
        if ([decoder allowsKeyedCoding])
        {
            self.font = [decoder decodeObjectForKey:NOODLE_FONT_CODING_KEY];
            self.textColor = [decoder decodeObjectForKey:NOODLE_TEXT_COLOR_CODING_KEY];
            self.alternateTextColor = [decoder decodeObjectForKey:NOODLE_ALT_TEXT_COLOR_CODING_KEY];
            _backgroundColor = [decoder decodeObjectForKey:NOODLE_BACKGROUND_COLOR_CODING_KEY];
        }
        else
        {
            self.font = [decoder decodeObject];
            self.textColor = [decoder decodeObject];
            self.alternateTextColor = [decoder decodeObject];
            _backgroundColor = [decoder decodeObject];
        }
        
        _linesToMarkers = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    
    if ([encoder allowsKeyedCoding])
    {
        [encoder encodeObject:self.font forKey:NOODLE_FONT_CODING_KEY];
        [encoder encodeObject:self.textColor forKey:NOODLE_TEXT_COLOR_CODING_KEY];
        [encoder encodeObject:self.alternateTextColor forKey:NOODLE_ALT_TEXT_COLOR_CODING_KEY];
        [encoder encodeObject:self.backgroundColor forKey:NOODLE_BACKGROUND_COLOR_CODING_KEY];
    }
    else
    {
        [encoder encodeObject:self.font];
        [encoder encodeObject:self.textColor];
        [encoder encodeObject:self.alternateTextColor];
        [encoder encodeObject:self.backgroundColor];
    }
}

#pragma mark - Notifications

- (void)clientTextStorageDidProcessEditing:(NSNotification *)notification
{
    // Invalidate the line indices. They will be recalculated and recached on demand.
    [self invalidateLineIndices];
    
    [self setNeedsDisplay:YES];
}

@end
