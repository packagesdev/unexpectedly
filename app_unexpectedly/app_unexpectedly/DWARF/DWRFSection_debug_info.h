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

#import "DWRFEnums.h"

#import "DWRFSection_debug_line.h"

#import "DWRFObject.h"

@class DWRFFileObject;

@interface DWRFDIEAttribute : NSObject

    @property DW_FORM form;

    @property id object;

    @property (nonatomic,readonly) BOOL isAddress;

    @property (nonatomic,readonly) BOOL isConstant;

@end

@interface DWRFDebuggingInformationEntry : NSObject

    @property (readonly) uint64_t abbreviationCode;

    @property (readonly) DW_TAG tag;

    @property (readonly) NSDictionary<NSNumber *,DWRFDIEAttribute *> * attributes;

    @property (readonly) DWRFDebuggingInformationEntry * parent;

    @property (readonly) DWRFDebuggingInformationEntry * next;

    @property (readonly) NSArray * children;

    @property (readonly) DWRFDebuggingInformationEntry * referencedEntry;


    @property (nonatomic,readonly,copy) NSString * name;        // attributes[@(DW_AT_name)]

+ (DWRFDebuggingInformationEntry *)nilEntry;

- (id)objectForAttribute:(DW_AT)inAttribute;

- (DWRFDebuggingInformationEntry *)entryAtAddress:(uint8_t *)inAddress;

- (BOOL)pcRangeContainsMachineInstructionAddress:(uint64_t)inMachineInstructionAddress;

@end

@interface DWRFCompileUnitEntry : DWRFDebuggingInformationEntry

    @property (nonatomic,readonly) uint64_t lineNumberProgramOffset;

    @property (nonatomic,readonly,copy) NSString * compiler;

    @property (nonatomic,readonly) DW_LANG language;

    @property (nonatomic,readonly,copy) NSString * compilationDirectory;

@end

@interface DWRFLexicalBlockEntry : DWRFDebuggingInformationEntry

@end


@interface DWRFSubProgramEntry : DWRFDebuggingInformationEntry

@property (nonatomic,readonly) uint64_t machineInstructionAddress;

    @property (readonly) NSUInteger sourcePathIndex;

    @property (nonatomic,readonly) uint64_t line;

- (NSString *)stackFrameSymbolWithLanguage:(DW_LANG)inLanguage;

@end

@interface DWRFDebuggingInformationCompilationUnit : DWRFObject

    @property (nonatomic,readonly) DWRFLineNumberProgram * lineNumberProgram;

    @property (nonatomic,readonly) DW_LANG language;

- (DWRFDebuggingInformationEntry *)entryAtAddress:(uint8_t *)inAddress;

- (DWRFSubProgramEntry *)subProgramForMachineInstructionAddress:(uint64_t)inAddress;

@end


@interface DWRFSection_debug_info : NSObject

@property (readonly) DWRFFileObject * fileObject;

- (instancetype)initWithData:(NSData *)inData fileObject:(DWRFFileObject *)inFileObject;

- (DWRFDebuggingInformationCompilationUnit *)compilationUnitAtOffset:(uint64_t)inOffset;

@end
