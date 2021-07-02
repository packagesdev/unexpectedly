/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DWRFSection_debug_info.h"

#import "DWRFFileObject.h"

#include "LEB128.h"

#import "CUICXXDemangler.h"
#import "CUISwiftDemangler.h"

@implementation DWRFDIEAttribute

- (BOOL)isAddress
{
    switch(self.form)
    {
        case DW_FORM_addr:
        case DW_FORM_addrx:
        case DW_FORM_addrx1:
        case DW_FORM_addrx2:
        case DW_FORM_addrx3:
        case DW_FORM_addrx4:
            
            return YES;
        
        default:
            
            break;
    }
    
    return NO;
}

- (BOOL)isConstant
{
    switch(self.form)
    {
        case DW_FORM_data1:
        case DW_FORM_data2:
        case DW_FORM_data4:
        case DW_FORM_data8:
        case DW_FORM_data16:
            
        case DW_FORM_sdata:
        case DW_FORM_udata:
            
        case DW_FORM_implicit_const:
            
            return YES;
            
            
        default:
            
            break;
    }
    
    return NO;
}

- (BOOL)iString
{
    switch(self.form)
    {
        case DW_FORM_strp:
        case DW_FORM_strx1:
        case DW_FORM_strx2:
        case DW_FORM_strx3:
        case DW_FORM_strx4:
            
        case DW_FORM_strx:
            
            return YES;
            
            
        default:
            
            break;
    }
    
    return NO;
}

- (NSString *)description
{
    if (self.isAddress==YES)
    {
        NSNumber * tNumber=self.object;
        
        return [NSString stringWithFormat:@"0x%016lx",[tNumber unsignedIntegerValue]];
    }
    
    return [self.object description];
}

@end

@interface DWRFDebuggingInformationEntry ()

    @property uint8_t * address;

    @property uint64_t abbreviationCode;

    @property DW_TAG tag;

    @property NSDictionary<NSNumber *,DWRFDIEAttribute *> * attributes;

    @property DWRFDebuggingInformationEntry * parent;

    @property DWRFDebuggingInformationEntry * next;

    @property NSArray * children;

    @property DWRFDebuggingInformationEntry * referencedEntry;

@end

@implementation DWRFDebuggingInformationEntry

+ (DWRFDebuggingInformationEntry *)nilEntry
{
    static DWRFDebuggingInformationEntry * sNilEntry=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sNilEntry=[DWRFDebuggingInformationEntry new];
        
        sNilEntry.abbreviationCode=0;
        sNilEntry.tag=0;
        
    });
    
    return sNilEntry;
}

#pragma mark -

- (NSString *)name
{
    NSString * tName=self.referencedEntry.attributes[@(DW_AT_name)].object;
    
    if (tName==nil)
        tName=self.attributes[@(DW_AT_name)].object;
    
    return [tName copy];
}

#pragma mark -

- (id)objectForAttribute:(DW_AT)inAttribute
{
    return self.attributes[@(inAttribute)].object;
}

- (DWRFDebuggingInformationEntry *)entryAtAddress:(uint8_t *)inAddress
{
    if (self.address==inAddress)
        return self;
    
    for(DWRFDebuggingInformationEntry * tChild in self.children)
    {
        DWRFDebuggingInformationEntry * tEntry=[tChild entryAtAddress:inAddress];
        
        if (tEntry!=nil)
            return tEntry;
    }
    
    return nil;
}

- (BOOL)pcRangeContainsMachineInstructionAddress:(uint64_t)inMachineInstructionAddress
{
    NSNumber * tNumber=[self objectForAttribute:DW_AT_low_pc];
    
    if (tNumber==nil)
        return NO;
    
    uint64_t tLowPC=[tNumber unsignedLongLongValue];
    
    if (inMachineInstructionAddress<tLowPC)
        return NO;
    
    DWRFDIEAttribute * tHighPCAttribute=self.attributes[@(DW_AT_high_pc)];
    
    tNumber=tHighPCAttribute.object;
    
    if (tNumber==nil)
        return NO;
    
    uint64_t tHighPC=[tNumber unsignedLongLongValue];
    
    if (tHighPCAttribute.isAddress==YES)    // HighPC is an address
    {
        return (inMachineInstructionAddress<tHighPC);
    }
    
    // HighPC is an offset from LowPC
    
    return (inMachineInstructionAddress<(tLowPC+tHighPC));
}


- (NSString *)nameForAttribute:(DW_AT)inAttribute
{
    static NSDictionary * sRegistry=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sRegistry=@{
                    @(0x01):@"DW_AT_sibling",
                    @(0x02):@"DW_AT_location",
                    @(0x03):@"DW_AT_name",
                    @(0x09):@"DW_AT_ordering",
                    @(0x0b):@"DW_AT_byte_size",
                    
                    @(0x10):@"DW_AT_stmt_list",
                    @(0x11):@"DW_AT_low_pc",
                    @(0x12):@"DW_AT_high_pc",
                    @(0x13):@"DW_AT_language",
                    
                    @(0x1b):@"DW_AT_comp_dir",
                    
                    @(0x20):@"DW_AT_inline",
                    
                    @(0x25):@"DW_AT_producer",
                    
                    @(0x27):@"DW_AT_prototyped",
                    
                    @(0x31):@"DW_AT_abstract_origin",
                    @(0x34):@"DW_AT_artificial",
                    
                    @(0x38):@"DW_AT_data_member_location",
                    
                    @(0x3a):@"DW_AT_decl_file",
                    @(0x3b):@"DW_AT_decl_line",
                    
                    @(0x3f):@"DW_AT_external",
                    
                    @(0x40):@"DW_AT_frame_base",
                    
                    @(0x47):@"DW_AT_specification",
                    
                    @(0x49):@"DW_AT_type",
                    
                    @(0x58):@"DW_AT_call_file",
                    @(0x59):@"DW_AT_call_line",
                    
                    @(0x64):@"DW_AT_object_pointer",
                    
                    @(0x6e):@"DW_AT_linkage_name",
                    
                    @(0x3e00):@"DW_AT_LLVM_include_path",
                    
                    @(0x3fe1):@"DW_AT_APPLE_optimized",
                    @(0x3fe1):@"DW_AT_APPLE_flags",
                    @(0x3fe5):@"DW_AT_APPLE_major_runtime_vers",
                    @(0x3fe6):@"DW_AT_APPLE_runtime_class",
                    };
        
    });
    
    NSString * tName=sRegistry[@(inAttribute)];
    
    if (tName!=nil)
        return tName;
    
    return [NSString stringWithFormat:@"%hu",inAttribute];
}

- (NSString *)nameForTag:(DW_TAG)inTag
{
    static NSDictionary * sRegistry=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sRegistry=@{
                    @(0x01):@"DW_TAG_array_type",
                    @(0x02):@"DW_TAG_class_type",
                    @(0x03):@"DW_TAG_entry_point",
                    @(0x04):@"DW_TAG_enumeration_type",
                    @(0x05):@"DW_TAG_formal_parameter",
                    @(0x08):@"DW_TAG_imported_declaration",
                    @(0x0a):@"DW_TAG_label",
                    @(0x0b):@"DW_TAG_lexical_block",
                    @(0x0d):@"DW_TAG_member",
                    @(0x0f):@"DW_TAG_pointer_type",
                    @(0x10):@"DW_TAG_reference_type",
                    @(0x11):@"DW_TAG_compile_unit",
                    @(0x12):@"DW_TAG_string_type",
                    
                    @(0x1d):@"DW_TAG_inlined_subroutine",
                    
                    @(0x24):@"DW_TAG_base_type",
                    
                    @(0x2e):@"DW_TAG_subprogram",
                    
                    @(0x3a):@"DW_TAG_imported_module",
                    };
        
    });
    
    NSString * tName=sRegistry[@(inTag)];
    
    if (tName!=nil)
        return tName;
    
    return [NSString stringWithFormat:@"%hu",inTag];
}

#pragma mark -

- (NSString *)description
{
    NSMutableString * tMutableString=[NSMutableString string];
    
    [tMutableString appendFormat:@"<%@:0x%llX> (%llu)\n",NSStringFromClass(self.class),(unsigned long long)self,self.abbreviationCode];
    
    [tMutableString appendFormat:@"Tag: %@\n",[self nameForTag:self.tag]];
    
    [tMutableString appendFormat:@"Attributes:\n"];
    
    [self.attributes enumerateKeysAndObjectsUsingBlock:^(NSNumber * bKey, DWRFDIEAttribute * bAttribute, BOOL * bOutStop) {
        
        [tMutableString appendFormat:@"\t %@ : %@\n",[self nameForAttribute:[bKey unsignedShortValue]],bAttribute];
        
        
    }];
    
    return tMutableString;
}

@end

@implementation DWRFCompileUnitEntry

- (uint64_t)lineNumberProgramOffset
{
    return [[self objectForAttribute:DW_AT_stmt_list] unsignedIntegerValue];
}

- (NSString *)compiler
{
    return [self objectForAttribute:DW_AT_producer];
}

- (DW_LANG)language
{
    return [[self objectForAttribute:DW_AT_language] unsignedShortValue];
}

- (NSString *)compilationDirectory
{
    return [self objectForAttribute:DW_AT_comp_dir];
}

@end

@implementation DWRFLexicalBlockEntry

@end


@implementation DWRFSubProgramEntry

- (uint64_t)machineInstructionAddress
{
    NSNumber * tNumber=[self.referencedEntry objectForAttribute:DW_AT_low_pc];
    
    if (tNumber==nil)
        tNumber=[self objectForAttribute:DW_AT_low_pc];;
    
    return [tNumber unsignedIntegerValue];
}



- (NSUInteger)sourcePathIndex
{
    NSNumber * tNumber=[self.referencedEntry objectForAttribute:DW_AT_decl_file];
    
    if (tNumber==nil)
        tNumber=[self objectForAttribute:DW_AT_decl_file];
    
    return [tNumber unsignedIntegerValue];
}

- (uint64_t)line
{
    NSNumber * tNumber=[self.referencedEntry objectForAttribute:DW_AT_decl_line];
    
    if (tNumber==nil)
        tNumber=[self objectForAttribute:DW_AT_decl_line];
    
    return [tNumber unsignedIntegerValue];
}

- (NSString *)stackFrameSymbolWithLanguage:(DW_LANG)inLanguage
{
    switch(inLanguage)
    {
        case DW_LANG_Swift:
        {
            NSString * tName=nil;
            
            NSString * tLinkageName=[self objectForAttribute:DW_AT_linkage_name];
            
            if (tLinkageName!=nil)
            {
                tName=[CUISwiftDemangler demangle:tLinkageName];
                
                if (tName!=nil)
                    return tName;
            }
            
            tName=self.name;
            
            DWRFDebuggingInformationEntry * tParentEntry=self;
            
            BOOL tNeedsParenthesis=NO;
            
            do
            {
                tParentEntry=tParentEntry.parent;
                
                DW_TAG tTag=tParentEntry.tag;
                
                if (tParentEntry==nil || tTag==DW_TAG_module || tTag==DW_TAG_compile_unit)
                    break;
                
                NSString * tComponentName=tParentEntry.name;
                
                if (tComponentName==nil)
                    break;
                
                tName=[NSString stringWithFormat:@"%@.%@",tComponentName,tName];
                
                tNeedsParenthesis=YES;
                
            } while (1);
            
            if (tNeedsParenthesis==YES)
                tName=[tName stringByAppendingString:@"()"];
            
            return tName;
        }
        
        case DW_LANG_C_plus_plus:
        {
            DWRFDebuggingInformationEntry * tParentEntry=self;
            NSString * tLinkageName=[self objectForAttribute:DW_AT_linkage_name];
            NSString * tName=nil;
            
            if (tLinkageName==nil && self.referencedEntry!=nil)
            {
                tLinkageName=[self.referencedEntry objectForAttribute:DW_AT_linkage_name];
            }
            
            if (tLinkageName!=nil)
            {
                tName=[CUICXXDemangler demangle:tLinkageName];
                
                if (tName!=nil)
                    return tName;
            }
            
            tName=tParentEntry.name;
            
            if (tName==nil && self.referencedEntry!=nil)
            {
                tParentEntry=self.referencedEntry;
                tName=tParentEntry.name;
            }
            
            BOOL tNeedsParenthesis=NO;
            
            do
            {
                tParentEntry=tParentEntry.parent;
                
                DW_TAG tTag=tParentEntry.tag;
                
                if (tParentEntry==nil || tTag==DW_TAG_module || tTag==DW_TAG_compile_unit)
                    break;
                
                NSString * tComponentName=tParentEntry.name;
                
                if (tComponentName==nil)
                    break;
                
                tName=[NSString stringWithFormat:@"%@::%@",tComponentName,tName];
                
                tNeedsParenthesis=YES;
            } while (1);
            
            // Parameters (A COMPLETER)
            
            if (tNeedsParenthesis==YES)
                tName=[tName stringByAppendingString:@"()"];
            
            return tName;
        }
            
        default:
            
            break;
    }
    
    return self.name;
}

@end



@interface DWRFDebuggingInformationCompilationUnitHeader : DWRFObject

    @property uint64_t unit_length;

    @property uint16_t version;

    @property uint8_t unit_type;

    @property uint64_t debug_abbrev_offset;

    @property uint8_t address_size;

- (instancetype)initWithBuffer:(uint8_t *)inBuffer outBuffer:(uint8_t **)outBuffer;

@end

@implementation DWRFDebuggingInformationCompilationUnitHeader

- (instancetype)initWithBuffer:(uint8_t *)inBuffer outBuffer:(uint8_t **)outBuffer
{
    if (inBuffer==NULL)
        return nil;
    
    self=[super init];
    
    if (self!=nil)
    {
        uint32_t tUnsignedInteger=*((uint32_t *)inBuffer);
        inBuffer+=sizeof(uint32_t);
        
        if (tUnsignedInteger==0xffffffff)
        {
            self.dwarfFormat=DWRF64Format;
            
            _unit_length=*((uint64_t *)inBuffer);
            inBuffer+=sizeof(uint64_t);
        }
        else
        {
            self.dwarfFormat=DWRF32Format;
            _unit_length=tUnsignedInteger;
            
        }
        
        _version=*((uint16_t *)inBuffer);
        inBuffer+=sizeof(uint16_t);
        
        if (_version>=5)
        {
            _unit_type=*((uint8_t *)inBuffer);
            inBuffer+=sizeof(uint8_t);
            
            _address_size=*((uint8_t *)inBuffer);
            inBuffer+=sizeof(uint8_t);
            
            if (self.dwarfFormat==DWRF64Format)
            {
                _debug_abbrev_offset=*((uint64_t *)inBuffer);
                inBuffer+=sizeof(uint64_t);
            }
            else
            {
                _debug_abbrev_offset=*((uint32_t *)inBuffer);
                inBuffer+=sizeof(uint32_t);
            }
        }
        else
        {
            if (self.dwarfFormat==DWRF64Format)
            {
                _debug_abbrev_offset=*((uint64_t *)inBuffer);
                inBuffer+=sizeof(uint64_t);
            }
            else
            {
                _debug_abbrev_offset=*((uint32_t *)inBuffer);
                inBuffer+=sizeof(uint32_t);
            }
        
            _address_size=*((uint8_t *)inBuffer);
            inBuffer+=sizeof(uint8_t);
        }
    }
    
    if (outBuffer!=NULL)
        *outBuffer=inBuffer;
    
    return self;
}

@end

@interface DWRFDebuggingInformationCompilationUnit ()
{
    uint8_t * _address;
    
    DWRFFileObject *_fileObject;
    
    NSArray * _abbreviationDeclarations;
    
    DWRFCompileUnitEntry * _compileUnitEntry;
    
    NSMutableArray<DWRFSubProgramEntry *> * _allSubProgramEntities;
}

@property DWRFDebuggingInformationCompilationUnitHeader * header;

- (instancetype)initWithBuffer:(uint8_t *)inBuffer fileObject:(DWRFFileObject *)inFileObject outBuffer:(uint8_t **)outBuffer;

- (DWRFDebuggingInformationEntry *)entryWithBuffer:(uint8_t *)inBuffer outBuffer:(uint8_t **)outBuffer;

@end

@implementation DWRFDebuggingInformationCompilationUnit

- (DWRFDebuggingInformationEntry *)entryWithBuffer:(uint8_t *)inBuffer outBuffer:(uint8_t **)outBuffer
{
    if (inBuffer==nil)
        return nil;
    
    uint8_t * tAddress=inBuffer;
    
    DWRFDebuggingInformationEntry * tEntry=nil;
    
    uint64_t tAbbreviationCode=DWRF_readULEB128(inBuffer, &inBuffer);
    
    if (tAbbreviationCode==0)
    {
        if (outBuffer!=NULL)
            *outBuffer=inBuffer;
        
        return [DWRFDebuggingInformationEntry nilEntry];
    }
    
    
    
    DWRFAbbreviationDeclaration * tAbbreviationDeclaration=_abbreviationDeclarations[tAbbreviationCode-1];
    
    // Tag
    
    DW_TAG tTag=tAbbreviationDeclaration.tag;
    
    switch(tTag)
    {
        case DW_TAG_lexical_block:
            
            tEntry=[DWRFLexicalBlockEntry new];
            
            break;
            
        case DW_TAG_compile_unit:
            
            tEntry=[DWRFCompileUnitEntry new];
            
            break;
            
        case DW_TAG_subprogram:
            
            tEntry=[DWRFSubProgramEntry new];
            
            break;
        
        default:
            
            tEntry=[DWRFDebuggingInformationEntry new];
            
            break;
            
    }

    if (tEntry!=nil)
    {
        tEntry.address=tAddress;
        
        tEntry.abbreviationCode=tAbbreviationCode;
        
        tEntry.tag=tAbbreviationDeclaration.tag;
        
        // Code
        
        tEntry.abbreviationCode=tAbbreviationCode;
        
        NSMutableDictionary * tAttributesDictionary=[NSMutableDictionary dictionary];
        
        
        
        // Attributes
        
        for(DWRFAttributeSpecification * tSpecification in tAbbreviationDeclaration.allAttributesSpecifications)
        {
            NSNumber * tKey=@(tSpecification.name);
            id tObject=nil;
            
            switch(tSpecification.form)
            {
                case DW_FORM_addr:
                {
                    uint64_t tAddress;
                    
                    memcpy(&tAddress,inBuffer,_header.address_size*sizeof(uint8_t));
                    inBuffer+=_header.address_size*sizeof(uint8_t);
                    
                    tObject=@(tAddress);
                
                    break;
                }
                    
                case DW_FORM_block:
                {
                    uint64_t tBlockLength=DWRF_readULEB128(inBuffer, &inBuffer);
                    
                    NSData * tData=[NSData dataWithBytes:inBuffer length:tBlockLength];
                    
                    inBuffer+=tBlockLength;
                    
                    tObject=tData;
                
                    break;
                }
                    
                case DW_FORM_block1:
                {
                    uint8_t tBlockLength=*((uint8_t *)inBuffer);
                    inBuffer+=sizeof(uint8_t);
                    
                    NSData * tData=[NSData dataWithBytes:inBuffer length:tBlockLength];
                    
                    inBuffer+=tBlockLength;
                    
                    tObject=tData;
                    
                    break;
                }
                
                case DW_FORM_block2:
                {
                    uint16_t tLength=*((uint16_t *)inBuffer);
                    inBuffer+=sizeof(uint16_t);
                    
                    tObject=[NSData dataWithBytes:inBuffer length:tLength];
                    
                    inBuffer+=tLength*sizeof(uint8_t);
                
                    break;
                }
                    
                case DW_FORM_block4:
                {
                    uint32_t tLength=*((uint32_t *)inBuffer);
                    inBuffer+=sizeof(uint32_t);
                    
                    tObject=[NSData dataWithBytes:inBuffer length:tLength];
                    
                    inBuffer+=tLength*sizeof(uint8_t);
                    
                    break;
                }
                
                case DW_FORM_data1:
                {
                    uint8_t tConstant=*((uint8_t *)inBuffer);
                    inBuffer+=sizeof(uint8_t);
                    
                    tObject=@(tConstant);
                
                    break;
                }
                    
                case DW_FORM_data2:
                {
                    uint16_t tConstant=*((uint16_t *)inBuffer);
                    inBuffer+=sizeof(uint16_t);
                    
                    tObject=@(tConstant);
                    
                    break;
                }
                    
                case DW_FORM_data4:
                {
                    uint32_t tConstant=*((uint32_t *)inBuffer);
                    inBuffer+=sizeof(uint32_t);
                    
                    tObject=@(tConstant);
                
                    break;
                }
                    
                case DW_FORM_data8:
                {
                    uint64_t tConstant=*((uint64_t *)inBuffer);
                    inBuffer+=sizeof(uint64_t);
                    
                    tObject=@(tConstant);

                    break;
                }
                
                case DW_FORM_data16:
                {
                    tObject=[NSData dataWithBytes:inBuffer length:16*sizeof(uint8_t)];
                    inBuffer+=16*sizeof(uint8_t);
                
                    break;
                }
                
                case DW_FORM_implicit_const:
                {
                    // A COMPLETER
                
                    break;
                }
                    
                    
                /*case DW_FORM_string:
                {
                }
                    
                    break;
                */

                    
                case DW_FORM_flag:
                {
                    uint8_t tPresent=*((uint8_t *)inBuffer);
                    inBuffer+=sizeof(uint8_t);
                    
                    tObject=[NSNumber numberWithBool:(tPresent!=0)];
                    
                    break;
                }
                    
                case DW_FORM_sdata:
                {
                    int64_t tConstant=DWRF_readLEB128(inBuffer, &inBuffer);
                    
                    tObject=@(tConstant);
                    
                    break;
                }
                    
                case DW_FORM_strp:
                {
                    uint64_t tOffset=0;
                    
                    if (self.dwarfFormat==DWRF64Format)
                    {
                        tOffset=*((uint64_t *)inBuffer);
                        inBuffer+=sizeof(uint64_t);
                    }
                    else
                    {
                        tOffset=*((uint32_t *)inBuffer);
                        inBuffer+=sizeof(uint32_t);
                    }
                    
                    tObject=[_fileObject.section_debug_str stringAtOffset:tOffset];
                    
                    break;
                }
                    
                case DW_FORM_udata:
                {
                    uint64_t tConstant=DWRF_readULEB128(inBuffer, &inBuffer);
                    
                    tObject=@(tConstant);
                    
                    break;
                }
                    
                case DW_FORM_ref_addr:
                {
                    uint64_t tAddress=0;
                    
                    if (self.header.version>=3)
                    {
                        if (self.dwarfFormat==DWRF64Format)
                        {
                            tAddress=*((uint64_t *)inBuffer);
                            inBuffer+=sizeof(uint64_t);
                        }
                        else
                        {
                            tAddress=*((uint32_t *)inBuffer);
                            inBuffer+=sizeof(uint32_t);
                        }
                    }
                    else
                    {
                        switch(self.header.address_size)
                        {
                            case 4:
                                
                                tAddress=*((uint32_t *)inBuffer);
                                inBuffer+=sizeof(uint32_t);
                                
                                break;
                                
                            case 8:
                                
                                tAddress=*((uint64_t *)inBuffer);
                                inBuffer+=sizeof(uint64_t);
                                
                                break;
                        }
                    }
                    
                    tObject=@(tAddress);
                    
                    break;
                }
                    
                /*case DW_FORM_ref1:
                {
                }
                    
                    break;
                    
                case DW_FORM_ref2:
                {
                }
                    
                    break;*/
                    
                case DW_FORM_ref4:
                {
                    uint32_t tReference=*((uint32_t *)inBuffer);
                    inBuffer+=sizeof(uint32_t);
                    
                    tObject=@(tReference);
                    
                    break;
                }
                    
                /*case DW_FORM_ref8:
                {
                }
                    
                    break;
                    
                case DW_FORM_ref_udata:
                {
                }
                    
                    break;
                    
                case DW_FORM_indirect:
                {
                }
                    
                    break;*/
                    
                case DW_FORM_sec_offset:
                {
                    uint64_t tOffset=0;
                    
                    if (self.dwarfFormat==DWRF64Format)
                    {
                        tOffset=*((uint64_t *)inBuffer);
                        inBuffer+=sizeof(uint64_t);
                    }
                    else
                    {
                        tOffset=*((uint32_t *)inBuffer);
                        inBuffer+=sizeof(uint32_t);
                    }
                    
                    tObject=@(tOffset);
                    
                    break;
                }
                    
                case DW_FORM_exprloc:
                {
                    uint64_t tLength=DWRF_readULEB128(inBuffer, &inBuffer);
                    
                    inBuffer+=tLength*sizeof(uint8_t);
                    
                    // A COMPLETER
                    
                    break;
                }
                    
                case DW_FORM_flag_present:
                {
                    // Implicitly indicated as present
                    
                    tObject=@(YES);
                    
                    break;
                }
                    
                /*case DW_FORM_reg_sig8:
                {
                }
                    
                    break;*/
                
                case DW_FORM_strx:
                {
                    uint64_t tIndex=DWRF_readULEB128(inBuffer,&inBuffer);
                    
                    NSNumber * tNumber=tAttributesDictionary[@(DW_AT_str_offsets_base)];
                    
                    if (tNumber==nil)
                    {
                        NSLog(@"Missing DW_AT_str_offsets_base");
                    }
                    
                    uint64_t tOffset=[_fileObject.section_debug_str_offsets offsetAtIndex:tIndex base:[tNumber unsignedIntegerValue] format:self.dwarfFormat];
                    
                    tObject=[_fileObject.section_debug_str stringAtOffset:tOffset];

                    break;
                }
                    
                case DW_FORM_addrx:
                {
                    uint64_t tIndex=DWRF_readULEB128(inBuffer,&inBuffer);
                    
                    NSNumber * tNumber=tAttributesDictionary[@(DW_AT_addr_base)];
                    
                    if (tNumber==nil)
                    {
                        NSLog(@"Missing DW_AT_addr_base");
                    }
                    
                    uint64_t tAddress=[_fileObject.section_debug_addr addressAtIndex:tIndex base:[tNumber unsignedIntegerValue] format:self.dwarfFormat];
                    
                    tObject=@(tAddress);

                    break;
                }
                    
                    
                case DW_FORM_strx1:
                {
                    uint8_t tIndex=*((uint8_t *)inBuffer);
                    inBuffer+=sizeof(uint8_t);
                    
                    NSNumber * tNumber=tAttributesDictionary[@(DW_AT_str_offsets_base)];
                    
                    if (tNumber==nil)
                    {
                        NSLog(@"Missing DW_AT_str_offsets_base");
                    }
                    
                    uint64_t tOffset=[_fileObject.section_debug_str_offsets offsetAtIndex:tIndex base:[tNumber unsignedIntegerValue] format:self.dwarfFormat];
                    
                    tObject=[_fileObject.section_debug_str stringAtOffset:tOffset];

                    break;
                }
                    
                case DW_FORM_strx2:
                {
                    uint16_t tIndex=*((uint16_t *)inBuffer);
                    inBuffer+=sizeof(uint16_t);
                    
                    NSNumber * tNumber=tAttributesDictionary[@(DW_AT_str_offsets_base)];
                    
                    if (tNumber==nil)
                    {
                        NSLog(@"Missing DW_AT_str_offsets_base");
                    }
                    
                    uint64_t tOffset=[_fileObject.section_debug_str_offsets offsetAtIndex:tIndex base:[tNumber unsignedIntegerValue] format:self.dwarfFormat];
                    
                    tObject=[_fileObject.section_debug_str stringAtOffset:tOffset];

                    break;
                }
                    
                case DW_FORM_strx3:
                {
                    uint16_t tIndex=*((uint32_t *)inBuffer);
                    inBuffer+=3*sizeof(uint8_t);
                    
                    tIndex=(tIndex>>8);
                    
                    NSNumber * tNumber=tAttributesDictionary[@(DW_AT_str_offsets_base)];
                    
                    if (tNumber==nil)
                    {
                        NSLog(@"Missing DW_AT_str_offsets_base");
                    }
                    
                    uint64_t tOffset=[_fileObject.section_debug_str_offsets offsetAtIndex:tIndex base:[tNumber unsignedIntegerValue] format:self.dwarfFormat];
                    
                    tObject=[_fileObject.section_debug_str stringAtOffset:tOffset];

                    break;
                }
                    
                case DW_FORM_strx4:
                {
                    uint32_t tIndex=*((uint32_t *)inBuffer);
                    inBuffer+=sizeof(uint32_t);
                    
                    NSNumber * tNumber=tAttributesDictionary[@(DW_AT_str_offsets_base)];
                    
                    if (tNumber==nil)
                    {
                        NSLog(@"Missing DW_AT_str_offsets_base");
                    }
                    
                    uint64_t tOffset=[_fileObject.section_debug_str_offsets offsetAtIndex:tIndex base:[tNumber unsignedIntegerValue] format:self.dwarfFormat];
                    
                    tObject=[_fileObject.section_debug_str stringAtOffset:tOffset];

                    break;
                }
                    
                case DW_FORM_addrx1:
                {
                    uint8_t tIndex=*((uint8_t *)inBuffer);
                    inBuffer+=sizeof(uint8_t);
                    
                    NSNumber * tNumber=tAttributesDictionary[@(DW_AT_addr_base)];
                    
                    if (tNumber==nil)
                    {
                        NSLog(@"Missing DW_AT_addr_base");
                    }
                    
                    uint64_t tAddress=[_fileObject.section_debug_addr addressAtIndex:tIndex base:[tNumber unsignedIntegerValue] format:self.dwarfFormat];
                    
                    tObject=@(tAddress);

                    break;
                }
                    
                case DW_FORM_addrx2:
                {
                    uint16_t tIndex=*((uint16_t *)inBuffer);
                    inBuffer+=sizeof(uint16_t);
                    
                    NSNumber * tNumber=tAttributesDictionary[@(DW_AT_addr_base)];
                    
                    if (tNumber==nil)
                    {
                        NSLog(@"Missing DW_AT_addr_base");
                    }
                    
                    uint64_t tAddress=[_fileObject.section_debug_addr addressAtIndex:tIndex base:[tNumber unsignedIntegerValue] format:self.dwarfFormat];
                    
                    tObject=@(tAddress);

                    break;
                }
                    
                case DW_FORM_addrx3:
                {
                    uint16_t tIndex=*((uint32_t *)inBuffer);
                    inBuffer+=3*sizeof(uint8_t);
                    
                    tIndex=(tIndex>>8);
                    
                    NSNumber * tNumber=tAttributesDictionary[@(DW_AT_addr_base)];
                    
                    if (tNumber==nil)
                    {
                        NSLog(@"Missing DW_AT_addr_base");
                    }
                    
                    uint64_t tAddress=[_fileObject.section_debug_addr addressAtIndex:tIndex base:[tNumber unsignedIntegerValue] format:self.dwarfFormat];
                    
                    tObject=@(tAddress);
                    
                    break;
                }
                    
                case DW_FORM_addrx4:
                {
                    uint32_t tIndex=*((uint32_t *)inBuffer);
                    inBuffer+=sizeof(uint32_t);
                    
                    NSNumber * tNumber=tAttributesDictionary[@(DW_AT_addr_base)];
                    
                    if (tNumber==nil)
                    {
                        NSLog(@"Missing DW_AT_addr_base");
                    }
                    
                    uint64_t tAddress=[_fileObject.section_debug_addr addressAtIndex:tIndex base:[tNumber unsignedIntegerValue] format:self.dwarfFormat];
                    
                    tObject=@(tAddress);

                    break;
                }
                    
                default:
                    
                    NSLog(@"FORM not handled: %lX",(unsigned long)tSpecification.form);
                    
                    break;
            }
            
            if (tObject!=nil)
            {
                DWRFDIEAttribute * tNewAttribute=[DWRFDIEAttribute new];
                
                tNewAttribute.form=tSpecification.form;
                tNewAttribute.object=tObject;
                
                tAttributesDictionary[tKey]=tNewAttribute;
            }
        }
        
        tEntry.attributes=tAttributesDictionary;
        
        
        if (tAbbreviationDeclaration.hasChildren)
        {
            NSMutableArray * tEntries=[NSMutableArray array];
            
            while (1)
            {
                DWRFDebuggingInformationEntry * tChildEntry=[self entryWithBuffer:inBuffer outBuffer:&inBuffer];
                
                if (tChildEntry==nil)
                {
                    NSLog(@"Error when unarchiving Debugging Information Entry");
                    
                    return nil;
                }
                
                if (tChildEntry.abbreviationCode==0)
                    break;
                
                tChildEntry.parent=tEntry;
                
                [tEntries addObject:tChildEntry];
            }
            
            tEntry.children=[tEntries copy];
        }
        
        if (outBuffer!=NULL)
            *outBuffer=inBuffer;
    }
    
    return tEntry;
}

- (instancetype)initWithBuffer:(uint8_t *)inBuffer fileObject:(DWRFFileObject *)inFileObject outBuffer:(uint8_t **)outBuffer
{
    if (inBuffer==nil)
        return nil;
    
    self=[super init];
    
    if (self!=nil)
    {
        _address=inBuffer;
        
        _fileObject=inFileObject;
        
        _header=[[DWRFDebuggingInformationCompilationUnitHeader alloc] initWithBuffer:inBuffer outBuffer:&inBuffer];
        
        self.dwarfFormat=_header.dwarfFormat;
        
        DWRFAbbreviationDeclarationsSet * tDeclarationsSet=[_fileObject.section_debug_abbrev abbreviationDeclarationsSetAtOffset:_header.debug_abbrev_offset];
        
        if (tDeclarationsSet==nil)
        {
            // Aie aie aie
            
            return nil;
        }
        
        _abbreviationDeclarations=tDeclarationsSet.allAbbreviationDeclarations;
        
        // Retrieve Compile Unit entry and its children
        
        _compileUnitEntry=(DWRFCompileUnitEntry *)[self entryWithBuffer:inBuffer outBuffer:&inBuffer];
            
        if (_compileUnitEntry==nil)
        {
            NSLog(@"Error when unarchiving Compile Unit Entry");
            
            return nil;
        }
        
        if (_compileUnitEntry.abbreviationCode==0)
        {
            NSLog(@"Error when unarchiving Compile Unit Entry");
            
            return nil;
        }
    }
    
    if (outBuffer!=NULL)
        *outBuffer=inBuffer;
    
    return self;
}

#pragma mark -

-(DW_LANG)language
{
    return _compileUnitEntry.language;
}

-(NSString *)compilationDirectory
{
    return _compileUnitEntry.compilationDirectory;
}

- (DWRFDebuggingInformationEntry *)entryAtAddress:(uint8_t *)inAddress
{
    return [_compileUnitEntry entryAtAddress:inAddress];
}

- (DWRFLineNumberProgram *)lineNumberProgram
{
    return [_fileObject.section_debug_line lineNumberProgramAtOffset:_compileUnitEntry.lineNumberProgramOffset];
}

- (DWRFSubProgramEntry *)subProgramForMachineInstructionAddress:(uint64_t)inMachineInstructionAddress
{
    if (_allSubProgramEntities==nil)
    {
        _allSubProgramEntities=[NSMutableArray array];
        
        __block __weak void (^_weakEnumerateNodesRecursively)(DWRFDebuggingInformationEntry *,NSMutableArray *);
        __block void(^_enumerateNodesRecursively)(DWRFDebuggingInformationEntry *,NSMutableArray *);
        
        _enumerateNodesRecursively = ^void(DWRFDebuggingInformationEntry * bEntry,NSMutableArray * bMutableArray)
        {
            if (bEntry.tag==DW_TAG_subprogram && [bEntry isKindOfClass:[DWRFSubProgramEntry class]]==YES)
            {
                [bMutableArray addObject:(DWRFSubProgramEntry *)bEntry];
            }
            
            for(DWRFDebuggingInformationEntry * bChildEntry in bEntry.children)
            {
                _weakEnumerateNodesRecursively(bChildEntry,bMutableArray);
            }
        };
        
        _weakEnumerateNodesRecursively = _enumerateNodesRecursively;
        
        _enumerateNodesRecursively(_compileUnitEntry,_allSubProgramEntities);
    }
    
    for(DWRFSubProgramEntry * tEntry in _allSubProgramEntities)
    {
        if (tEntry.tag==DW_TAG_subprogram)
        {
            if ([tEntry isKindOfClass:[DWRFSubProgramEntry class]]==YES)
            {
                DWRFSubProgramEntry * tSubProgramEntry=(DWRFSubProgramEntry *)tEntry;
                
                if ([tSubProgramEntry pcRangeContainsMachineInstructionAddress:inMachineInstructionAddress]==NO)
                    continue;
                
                // Look for inlined subroutines
                        
                for(DWRFDebuggingInformationEntry * tChild in tSubProgramEntry.children)
                {
                    if (tChild.tag==DW_TAG_inlined_subroutine)
                    {
                        if ([tChild pcRangeContainsMachineInstructionAddress:inMachineInstructionAddress]==YES)
                        {
                            NSNumber * tNumber=[tChild objectForAttribute:DW_AT_abstract_origin];
                            
                            if (tNumber!=nil)
                            {
                                uint64_t tOffset=[tNumber unsignedIntegerValue];
                                
                                DWRFDebuggingInformationEntry * tEntry=[_compileUnitEntry entryAtAddress:_address+tOffset];
                                
                                if ([tEntry isKindOfClass:[DWRFSubProgramEntry class]]==YES)
                                {
                                    tSubProgramEntry=(DWRFSubProgramEntry *)tEntry;
                                }
                            }
                            
                            break;
                        }
                    }
                }
                
                if (tSubProgramEntry.name==nil)
                {
                    NSNumber * tReference=[tSubProgramEntry objectForAttribute:DW_AT_specification];
                    
                    if (tReference!=nil)
                    {
                        DWRFDebuggingInformationEntry * tReferencedEntry=[self entryAtAddress:_address+[tReference unsignedIntegerValue]];
                        
                        if ([tReferencedEntry isKindOfClass:[DWRFSubProgramEntry class]]==YES)
                        {
                            tSubProgramEntry.referencedEntry=tReferencedEntry;
                        }
                        
                        
                    }
                }
                
                return tSubProgramEntry;
            }
        }
    }
    
    return nil;
}

@end

@interface DWRFSection_debug_info ()
{
    NSData * _cachedData;
    
    NSMutableDictionary<NSNumber *,DWRFDebuggingInformationCompilationUnit *> * _compilationUnits;
}

    @property DWRFFileObject * fileObject;

@end

@implementation DWRFSection_debug_info

- (instancetype)initWithData:(NSData *)inData fileObject:(DWRFFileObject *)inFileObject
{
    if (inData==nil || [inData isKindOfClass:[NSData class]]==NO)
        return nil;
    
    self=[super init];
    
    if (self!=nil)
    {
        _fileObject=inFileObject;
        
        _cachedData=inData;
        
        _compilationUnits=[NSMutableDictionary dictionary];
    }
    
    return self;
}

#pragma mark -

- (DWRFDebuggingInformationCompilationUnit *)compilationUnitAtOffset:(uint64_t)inOffset
{
    DWRFDebuggingInformationCompilationUnit * tCompilationUnit=_compilationUnits[@(inOffset)];
    
    if (tCompilationUnit!=nil)
        return tCompilationUnit;
    
    uint8_t * tBufferPtr=(uint8_t *)_cachedData.bytes;
    
    tBufferPtr=tBufferPtr+inOffset;
    
    tCompilationUnit=[[DWRFDebuggingInformationCompilationUnit alloc] initWithBuffer:tBufferPtr fileObject:self.fileObject outBuffer:&tBufferPtr];
    
    if (tCompilationUnit!=nil)
        _compilationUnits[@(inOffset)]=tCompilationUnit;
    
    
    return tCompilationUnit;
}

@end
