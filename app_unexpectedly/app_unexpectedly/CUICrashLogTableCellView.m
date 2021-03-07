/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogTableCellView.h"

#define RESIZING_BORDER   400

#define INTERSPACE_H    8

#define SMALL_WIDTH     71
#define LARGE_WIDTH     100

@implementation CUICrashLogTableCellView

- (void)layout
{
    NSRect tBounds=self.bounds;
    NSRect tFrame=self.exceptionTypeLabel.frame;
    
    if (tBounds.size.width>RESIZING_BORDER)
    {
        if (tFrame.size.width<(LARGE_WIDTH+1))
        {
            tFrame.origin.x=NSMaxX(tFrame)-LARGE_WIDTH;
            tFrame.size.width=LARGE_WIDTH;
            
            self.exceptionTypeLabel.frame=tFrame;
            
            NSRect tOtherFrame=self.dateLabel.frame;
            
            tOtherFrame.size.width=NSMinX(tFrame)-INTERSPACE_H-NSMinX(tOtherFrame);
            
            self.dateLabel.frame=tOtherFrame;
            
            tOtherFrame=self.textField.frame;
            
            tOtherFrame.size.width=NSMinX(tFrame)-INTERSPACE_H-NSMinX(tOtherFrame);
            
            self.textField.frame=tOtherFrame;
        }
    }
    else
    {
        if (tFrame.size.width>(SMALL_WIDTH+1))
        {
            tFrame.origin.x=NSMaxX(tFrame)-SMALL_WIDTH;
            tFrame.size.width=SMALL_WIDTH;
            
            self.exceptionTypeLabel.frame=tFrame;
            
            NSRect tOtherFrame=self.dateLabel.frame;
            
            tOtherFrame.size.width=NSMinX(tFrame)-INTERSPACE_H-NSMinX(tOtherFrame);
            
            self.dateLabel.frame=tOtherFrame;
            
            tOtherFrame=self.textField.frame;
            
            tOtherFrame.size.width=NSMinX(tFrame)-INTERSPACE_H-NSMinX(tOtherFrame);
            
            self.textField.frame=tOtherFrame;
        }
    }
}

@end
