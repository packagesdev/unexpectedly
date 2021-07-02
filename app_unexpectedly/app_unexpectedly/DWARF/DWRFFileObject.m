/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DWRFFileObject.h"

#import "MCHSegmentLoadCommand.h"

#include <mach-o/loader.h>
#include <mach-o/fat.h>

@interface DWRFFileObject ()
{
    MCHObjectFile * _cachedObjectFile;
}

    @property DWRFSection_debug_addr * section_debug_addr;

    @property DWRFSection_debug_str * section_debug_str;

    @property DWRFSection_debug_str_offsets * section_debug_str_offsets;

    @property DWRFSection_debug_abbrev * section_debug_abbrev;

    @property DWRFSection_debug_line * section_debug_line;

    @property DWRFSection_debug_info * section_debug_info;

    @property DWRFSection_debug_aranges * section_debug_aranges;

@end

@implementation DWRFFileObject

- (instancetype)initWithMachObjectFile:(MCHObjectFile *)inObjectFile
{
    if (inObjectFile==nil)
        return nil;
    
    if (inObjectFile.fileType!=MH_DSYM)
        return nil;
    
    self=[super init];
    
    if (self!=nil)
    {
        _cachedObjectFile=inObjectFile;
    }
    
    return self;
}

#pragma mark -

- (BOOL)analyze
{
    NSArray * tSegment64LoadCommands=[_cachedObjectFile loadCommandsOfType:LC_SEGMENT_64];
    
    for(MCHSegmentLoadCommand * tLoadCommand in tSegment64LoadCommands)
    {
        if ([tLoadCommand.segment.name isEqualToString:@"__DWARF"])
        {
            MCHSection * tSection=[tLoadCommand.segment sectionNamed:@"__debug_addr"];
            
            if (tSection!=nil)
            {
                _section_debug_addr=[[DWRFSection_debug_addr alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)tSection.buffer length:tSection.bufferSize freeWhenDone:NO]];
                
                if (_section_debug_addr==nil)
                {
                    // A COMPLETER
                    
                    return NO;
                }
            }
            
            tSection=[tLoadCommand.segment sectionNamed:@"__debug_str"];
            
            if (tSection!=nil)
            {
                _section_debug_str=[[DWRFSection_debug_str alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)tSection.buffer length:tSection.bufferSize freeWhenDone:NO]];
                
                if (_section_debug_str==nil)
                {
                    // A COMPLETER
                    
                    return NO;
                }
            }
            
            tSection=[tLoadCommand.segment sectionNamed:@"__debug_str_offsets"];
            
            if (tSection!=nil)
            {
                _section_debug_str_offsets=[[DWRFSection_debug_str_offsets alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)tSection.buffer length:tSection.bufferSize freeWhenDone:NO]];
                
                if (_section_debug_str_offsets==nil)
                {
                    // A COMPLETER
                    
                    return NO;
                }
            }
            
            tSection=[tLoadCommand.segment sectionNamed:@"__debug_abbrev"];
            
            if (tSection!=nil)
            {
                _section_debug_abbrev=[[DWRFSection_debug_abbrev alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)tSection.buffer length:tSection.bufferSize freeWhenDone:NO]];
                
                if (_section_debug_abbrev==nil)
                {
                    // A COMPLETER
                    
                    return NO;
                }
            }
            
            tSection=[tLoadCommand.segment sectionNamed:@"__debug_line"];
            
            if (tSection!=nil)
            {
                _section_debug_line=[[DWRFSection_debug_line alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)tSection.buffer length:tSection.bufferSize freeWhenDone:NO]];
                
                if (_section_debug_line==nil)
                {
                    // A COMPLETER
                    
                    return NO;
                }
            }
            
            tSection=[tLoadCommand.segment sectionNamed:@"__debug_info"];
            
            if (tSection!=nil)
            {
                _section_debug_info=[[DWRFSection_debug_info alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)tSection.buffer length:tSection.bufferSize freeWhenDone:NO] fileObject:self];
                
                if (_section_debug_info==nil)
                {
                    // A COMPLETER
                    
                    return NO;
                }
            }
            
            tSection=[tLoadCommand.segment sectionNamed:@"__debug_aranges"];
            
            if (tSection!=nil)
            {
                _section_debug_aranges=[[DWRFSection_debug_aranges alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)tSection.buffer length:tSection.bufferSize freeWhenDone:NO]];
                
                if (_section_debug_aranges==nil)
                {
                    // A COMPLETER
                    
                    return NO;
                }
            }
            
            return YES;
        }
    }
    
    return NO;
}

#pragma mark -

- (void)lookUpSymbolicationDataForMachineInstructionAddress:(uint64_t)inAddress completionHandler:(void (^)(BOOL bFound,CUISymbolicationData * bSymbolicationData))handler
{
    if (self.section_debug_info==nil)
    {
        if ([self analyze]==NO)
        {
            if (handler!=nil)
                handler(NO,nil);
            
            return;
        }
    }
    
    uint64_t tDebugInfoOffset=[self.section_debug_aranges debugInfoOffsetForAddress:inAddress];
    
    if (tDebugInfoOffset==UINT64_MAX)
    {
        if (handler!=nil)
            handler(NO,nil);
        
        return;
    }
    
    DWRFDebuggingInformationCompilationUnit * tCompilationUnit=[self.section_debug_info compilationUnitAtOffset:tDebugInfoOffset];
    
    if (tCompilationUnit==nil)
    {
        if (handler!=nil)
            handler(NO,nil);
        
        return;
    }
    
    // Look for the sub_program with inAddress for its AT_low_pc attribute
    
    DWRFSubProgramEntry * tSubProgramEntry=[tCompilationUnit subProgramForMachineInstructionAddress:inAddress];
    
    if (tSubProgramEntry==nil)
    {
        if (handler!=nil)
            handler(NO,nil);
        
        return;
    }
    
    DWRFLineNumberProgramLocation * tLocation=[tCompilationUnit.lineNumberProgram locationForMachineInstructionAddress:inAddress];
    
    if (tLocation!=nil)
    {
        CUISymbolicationData * tSymbolicationData=[CUISymbolicationData new];
        
        tSymbolicationData.stackFrameSymbol=[tSubProgramEntry stackFrameSymbolWithLanguage:tCompilationUnit.language];
        tSymbolicationData.byteOffset=inAddress-tSubProgramEntry.machineInstructionAddress;
        
        NSUInteger tFileIndex=tSubProgramEntry.sourcePathIndex;
        
        if (tFileIndex!=0)
        {
            // A AMELIORER (path absolu à trouver)
        }
        
        NSString * tFilePath=tLocation.fileName;
        
        if (tFilePath.length>0 && [tFilePath characterAtIndex:0]!='/')
        {
            NSString * tCompilationDirectory=tCompilationUnit.compilationDirectory;
            
            if (tCompilationDirectory.length>0)
                tFilePath=[tCompilationDirectory stringByAppendingPathComponent:tFilePath];
        }
        
        tSymbolicationData.sourceFilePath=tFilePath;
        
        tSymbolicationData.lineNumber=tLocation.lineNumber;
        tSymbolicationData.columnNumber=tLocation.columnNumber;
        
        handler(YES,tSymbolicationData);
        
        return;
    }
    
    // Not found, use less accurate data
    
        NSLog(@"0x%llX -> %@ %@ - %llu %llu",inAddress,tSubProgramEntry.name,tLocation.fileName,tLocation.lineNumber,tLocation.columnNumber);
    
    
    NSString * tSourceFilePath=@"-";
    
    NSUInteger tFileIndex=tSubProgramEntry.sourcePathIndex;
    
    if (tFileIndex!=0)
    {
        DWRFLineNumberProgram * tLineNumberProgram=[tCompilationUnit lineNumberProgram];
    
        if (tLineNumberProgram!=nil)
        {
            tSourceFilePath=[tLineNumberProgram fileNameAtIndex:tFileIndex];
            
            if (tSourceFilePath==nil)
            {
                tSourceFilePath=@"-";
            }
        }
    }
    
    NSLog(@"0x%llX -> %@ %@ - %llu",inAddress,tSubProgramEntry.name,tSourceFilePath,tSubProgramEntry.line);
    
    if (handler!=nil)
    {
        CUISymbolicationData * tSymbolicationData=[CUISymbolicationData new];
        
        tSymbolicationData.stackFrameSymbol=tSubProgramEntry.name;
        tSymbolicationData.byteOffset=inAddress-tSubProgramEntry.machineInstructionAddress;
        tSymbolicationData.sourceFilePath=tSourceFilePath;
        tSymbolicationData.lineNumber=tSubProgramEntry.line;
        
        handler(YES,tSymbolicationData);
    }
}

@end
