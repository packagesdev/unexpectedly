/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#import "MCHObjectFile.h"

#import "CUISymbolicationData.h"

#import "DWRFSection_debug_addr.h"

#import "DWRFSection_debug_str.h"

#import "DWRFSection_debug_str_offsets.h"

#import "DWRFSection_debug_abbrev.h"

#import "DWRFSection_debug_line.h"

#import "DWRFSection_debug_info.h"

#import "DWRFSection_debug_aranges.h"

@interface DWRFFileObject : NSObject

    @property (readonly) DWRFSection_debug_addr * section_debug_addr;

    @property (readonly) DWRFSection_debug_str * section_debug_str;

    @property (readonly) DWRFSection_debug_str_offsets * section_debug_str_offsets;

    @property (readonly) DWRFSection_debug_abbrev * section_debug_abbrev;

    @property (readonly) DWRFSection_debug_line * section_debug_line;

    @property (readonly) DWRFSection_debug_info * section_debug_info;

    @property (readonly) DWRFSection_debug_aranges * section_debug_aranges;


- (instancetype)initWithMachObjectFile:(MCHObjectFile *)inObjectFile;

- (void)lookUpSymbolicationDataForMachineInstructionAddress:(uint64_t)inAddress completionHandler:(void (^)(BOOL bFound,CUISymbolicationData * bSymbolicationData))handler;

@end
