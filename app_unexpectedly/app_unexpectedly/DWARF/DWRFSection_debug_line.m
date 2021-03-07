/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DWRFSection_debug_line.h"

#include "LEB128.h"

#import "DWRFObject.h"

typedef NS_ENUM(uint8_t, DW_LNS)
{
    DW_LNS_extended_op = 0x00,
    
    DW_LNS_copy = 0x01,
    DW_LNS_advance_pc = 0x02,
    DW_LNS_advance_line = 0x03,
    DW_LNS_set_file = 0x04,
    DW_LNS_set_column = 0x05,
    DW_LNS_negate_stmt = 0x06,
    DW_LNS_set_basic_block = 0x07,
    DW_LNS_const_add_pc = 0x08,
    DW_LNS_fixed_advance_pc = 0x09,
    DW_LNS_set_prologue_end = 0x0a,
    DW_LNS_set_epilogue_begin = 0x0b,
    DW_LNS_set_isa = 0x0c
};

typedef NS_ENUM(NSUInteger, DW_LNE)
{
    DW_LNE_end_sequence = 0x01,
    DW_LNE_set_address = 0x02,
    DW_LNE_define_file = 0x03,
    DW_LNE_set_discriminator = 0x04,
    DW_LNE_lo_user = 0x80,
    DW_LNE_hi_user = 0xff
};

@interface DWRFLineNumberProgramLocation ()

    @property uint64_t machineInstructionAddress;

    @property (copy) NSString * fileName;

    @property uint64_t lineNumber;

    @property uint64_t columnNumber;

@end

@implementation DWRFLineNumberProgramLocation

@end

@interface DWRFLineNumberProgramStateMachine : NSObject

    @property uint64_t address;

    @property uint64_t op_index;

    @property uint64_t file;

    @property uint64_t line;

    @property uint64_t column;

    @property BOOL is_stmt;

    @property BOOL basic_block;

    @property BOOL end_sequence;

    @property BOOL prologue_end;

    @property BOOL epilogue_begin;

    @property uint64_t xisa;

    @property uint64_t discriminator;

@end

@implementation DWRFLineNumberProgramStateMachine

- (instancetype)initWithStmt:(BOOL)inStmt;
{
    self=[super init];
    
    if (self!=nil)
    {
        _address=0;
        
        _op_index=0;
        
        _file=1;
        
        _line=1;
        
        _column=0;
        
        _is_stmt=inStmt;
        
        _basic_block=NO;
        
        _end_sequence=NO;
        
        _prologue_end=NO;
        
        _epilogue_begin=NO;
        
        _xisa=0;
        
        _discriminator=0;
    }
    
    return self;
}

@end

@interface DWRFLineNumberProgramHeaderFileNameEntry : NSObject

    @property NSString * filePath;

    @property uint64_t directoryIndex;

    @property uint64_t lastModificationDate;

    @property uint64_t fileSize;

@end


@implementation DWRFLineNumberProgramHeaderFileNameEntry

@end




@interface DWRFLineNumberProgramHeader : DWRFObject

    @property uint64_t unitLength;    // 4 bytes DWARF-32 / 12 bytes DWARF-64
    @property uint16_t version;

    @property uint64_t headerLength;  // 4 bytes DWARF-32 / 8 bytes DWARF-64

    @property uint8_t minimumInstructionLength;

    @property uint8_t maximumOperationsPerInstruction;

    @property uint8_t defaultIsStmt;

    @property int8_t lineBase;

    @property uint8_t lineRange;

    @property int8_t opcodeBase;

    @property uint8_t * standardOpcodeLengths;    // opcodeBase count

    @property NSMutableArray * includeDirectories;

    @property NSMutableArray * fileEntries;

- (instancetype)initWithBuffer:(uint8_t *)inBuffer outBuffer:(uint8_t **)outBuffer;

@end

@implementation DWRFLineNumberProgramHeader

- (instancetype)initWithBuffer:(uint8_t *)inBuffer outBuffer:(uint8_t **)outBuffer
{
    if (inBuffer==NULL)
        return nil;
    
    self=[super init];
    
    if (self!=nil)
    {
        uint32_t tUnsignedInteger;
        
        tUnsignedInteger=*((uint32_t *)inBuffer);
        inBuffer+=sizeof(uint32_t);
        
        if (tUnsignedInteger==0xffffffff)
        {
            self.dwarfFormat=DWRF64Format;
            
            _unitLength=*((uint64_t *)inBuffer);
            inBuffer+=sizeof(uint64_t);
        }
        else
        {
            _unitLength=tUnsignedInteger;
        }
        
        _version=*((uint16_t *)inBuffer);
        inBuffer+=sizeof(uint16_t);
        
        if (self.dwarfFormat==DWRF64Format)
        {
            _headerLength=*((uint64_t *)inBuffer);
            inBuffer+=sizeof(uint64_t);
            
            _headerLength+=18;
        }
        else
        {
            _headerLength=*((uint32_t *)inBuffer);
            inBuffer+=sizeof(uint32_t);
            
            _headerLength+=10;
        }
        
        
        
        _minimumInstructionLength=*((uint8_t *)inBuffer);
        inBuffer+=sizeof(uint8_t);
        
        
        if (_version>=4)
        {
            _maximumOperationsPerInstruction=*((uint8_t *)inBuffer);
            inBuffer+=sizeof(uint8_t);
        }
        else
        {
            _maximumOperationsPerInstruction=1;
        }
        
        _defaultIsStmt=*((uint8_t *)inBuffer);
        inBuffer+=sizeof(uint8_t);
        
        _lineBase=*((int8_t *)inBuffer);
        inBuffer+=sizeof(int8_t);
        
        _lineRange=*((uint8_t *)inBuffer);
        inBuffer+=sizeof(uint8_t);
        
        _opcodeBase=*((int8_t *)inBuffer);
        inBuffer+=sizeof(int8_t);
        
        
        _standardOpcodeLengths=malloc(_opcodeBase*sizeof(uint8_t));
        
        for(size_t tIndex=0;tIndex<(_opcodeBase-1);tIndex++)
            _standardOpcodeLengths[tIndex]=DWRF_readLEB128(inBuffer, &inBuffer);
        
        _includeDirectories=[NSMutableArray array];
        
        while((*inBuffer)!=0)
        {
            size_t tLength=strlen((char *)inBuffer);
            
            NSString * tString=[NSString stringWithCString:(char *)inBuffer encoding:NSUTF8StringEncoding];
            
            if (tString!=nil)
                [_includeDirectories addObject:tString];
            
            inBuffer+=(tLength+1);
        }
        
        inBuffer++;
        
        
        
        _fileEntries=[NSMutableArray array];
        
        while((*inBuffer)!=0)
        {
            DWRFLineNumberProgramHeaderFileNameEntry * tEntry=[DWRFLineNumberProgramHeaderFileNameEntry new];
            
            size_t tLength=strlen((char *)inBuffer);
            
            NSString * tString=[NSString stringWithCString:(char *)inBuffer encoding:NSUTF8StringEncoding];
            
            if (tString==nil)
                return nil;
            
            inBuffer+=(tLength+1);
            
            tEntry.filePath=tString;
            tEntry.directoryIndex=DWRF_readULEB128(inBuffer, &inBuffer);
            tEntry.lastModificationDate=DWRF_readULEB128(inBuffer, &inBuffer);
            tEntry.fileSize=DWRF_readULEB128(inBuffer, &inBuffer);
            
            [_fileEntries addObject:tEntry];
        }
        
        inBuffer++;
    }
    
    if (outBuffer!=NULL)
        *outBuffer=inBuffer;
    
    return self;
}

@end


@interface DWRFLineNumberProgram ()
{
    DWRFLineNumberProgramHeader * _header;
    
    uint8_t * _programBufferStart;
    uint8_t * _programBufferEnd;
    
    NSMutableArray * _locationsAddresses;
    
    NSMutableDictionary<NSNumber *,DWRFLineNumberProgramLocation *> * _locationsRegistry;
}

- (instancetype)initWithBuffer:(uint8_t *)inBuffer;

- (DWRFLineNumberProgramLocation *)locationFromStateMachine:(DWRFLineNumberProgramStateMachine *)inStateMachine;

@end

@implementation DWRFLineNumberProgram

- (instancetype)initWithBuffer:(uint8_t *)inBuffer
{
    if (inBuffer==NULL)
        return nil;
    
    self=[super init];
    
    if (self!=nil)
    {
        uint8_t * tBuffer=inBuffer;
        
        _header=[[DWRFLineNumberProgramHeader alloc] initWithBuffer:tBuffer outBuffer:&tBuffer];
        
        if (_header==nil)
        {
            NSLog(@"Error unarchiving Line Number Program Header");
            
            return nil;
        }
        
        _programBufferStart=inBuffer+_header.headerLength;
        _programBufferEnd=inBuffer+_header.unitLength;
    }
    
    return self;
}

#pragma mark -

- (NSString *)fileNameAtIndex:(NSUInteger)inIndex
{
    if (inIndex>_header.fileEntries.count)
        return nil;
    
    DWRFLineNumberProgramHeaderFileNameEntry * tEntry=_header.fileEntries[inIndex-1];
    
    return tEntry.filePath;
}

- (BOOL)runProgram
{
    _locationsAddresses=[NSMutableArray array];
    _locationsRegistry=[NSMutableDictionary dictionary];
    
    DWRFLineNumberProgramStateMachine * tStateMachine=[[DWRFLineNumberProgramStateMachine alloc] initWithStmt:_header.defaultIsStmt];
    
    BOOL tDone=NO;
    
    uint8_t * tBuffer=_programBufferStart;
    
    while (tBuffer<_programBufferEnd && tDone==NO)
    {
        uint8_t tOpcode=*tBuffer;
        tBuffer+=sizeof(uint8_t);
        
        if (tOpcode>=_header.opcodeBase)
        {
            // Special Opcode
            
            tOpcode-=_header.opcodeBase;
            
            uint8_t tOperationAdvance=tOpcode/_header.lineRange;
            
            tStateMachine.line+=_header.lineBase+ (tOpcode % _header.lineRange);
            
            tStateMachine.address+=_header.minimumInstructionLength*((tStateMachine.op_index+tOperationAdvance)/_header.maximumOperationsPerInstruction);
            
            tStateMachine.op_index=(tStateMachine.op_index+tOperationAdvance)%_header.maximumOperationsPerInstruction;
            
            tStateMachine.basic_block=NO;
            tStateMachine.prologue_end=NO;
            tStateMachine.epilogue_begin=NO;
            
            tStateMachine.discriminator=0;
            
            // Add a row to the matrix
            
            DWRFLineNumberProgramLocation * tLocation=[self locationFromStateMachine:tStateMachine];
            
            NSNumber * tKey=@(tStateMachine.address);
            
            [_locationsAddresses addObject:tKey];
            
            _locationsRegistry[tKey]=tLocation;

            continue;
        }
        
        if (tOpcode!=DW_LNS_extended_op)
        {
            // Standard Opcode
            
            switch(tOpcode)
            {
                case DW_LNS_copy:
                {
                    DWRFLineNumberProgramLocation * tLocation=[self locationFromStateMachine:tStateMachine];
                    
                    NSNumber * tKey=@(tStateMachine.address);
                    
                    [_locationsAddresses addObject:tKey];
                    
                    _locationsRegistry[tKey]=tLocation;
                    
                    tStateMachine.discriminator=0;
                    
                    tStateMachine.basic_block=NO;
                    tStateMachine.prologue_end=NO;
                    tStateMachine.epilogue_begin=NO;
                    
                    break;
                }
                case DW_LNS_advance_pc:
                {
                    uint64_t tOperationAdvance=DWRF_readULEB128(tBuffer, &tBuffer);
                    
                    tStateMachine.address+=_header.minimumInstructionLength*((tStateMachine.op_index+tOperationAdvance)/_header.maximumOperationsPerInstruction);
                    
                    tStateMachine.op_index=(tStateMachine.op_index+tOperationAdvance)%_header.maximumOperationsPerInstruction;
                    
                    break;
                    
                }
                    
                case DW_LNS_advance_line:
                    
                    tStateMachine.line+=DWRF_readLEB128(tBuffer, &tBuffer);
                    
                    break;
                    
                    
                case DW_LNS_set_file:
                    
                    tStateMachine.file=DWRF_readULEB128(tBuffer, &tBuffer);
                    
                    break;
                    
                case DW_LNS_set_column:
                    
                    tStateMachine.column=DWRF_readULEB128(tBuffer, &tBuffer);
                    
                    break;
                    
                case DW_LNS_negate_stmt:
                    
                    tStateMachine.is_stmt=!tStateMachine.is_stmt;
                    
                    break;
                    
                case DW_LNS_set_basic_block:
                    
                    tStateMachine.basic_block=YES;
                    
                    break;
                    
                case DW_LNS_const_add_pc:
                {
                    uint64_t tOperationAdvance=(255 - _header.opcodeBase) / _header.lineRange;
                    
                    tStateMachine.address+=_header.minimumInstructionLength*((tStateMachine.op_index+tOperationAdvance)/_header.maximumOperationsPerInstruction);
                    
                    tStateMachine.op_index=(tStateMachine.op_index+tOperationAdvance)%_header.maximumOperationsPerInstruction;
                    
                    break;
                }
                case DW_LNS_fixed_advance_pc:
                {
                    uint16_t tAdvance=*((uint16_t *)tBuffer);
                    tBuffer+=sizeof(uint16_t);
                    
                    
                    tStateMachine.address+=tAdvance;
                    
                    tStateMachine.op_index=0;
                    
                    break;
                }
                case DW_LNS_set_prologue_end:
                    
                    tStateMachine.prologue_end=YES;
                    
                    break;
                    
                case DW_LNS_set_epilogue_begin:
                    
                    tStateMachine.epilogue_begin=YES;
                    
                    break;
                    
                    
                case DW_LNS_set_isa:
                    
                    tStateMachine.xisa=DWRF_readULEB128(tBuffer, &tBuffer);
                    
                    break;
                    
                default:
                {
                    // Unsupported standard opcode
                    
                    uint8_t tArgumentsCount=_header.standardOpcodeLengths[tOpcode-1];
                    
                    while(tArgumentsCount>0)
                    {
                        DWRF_readULEB128(tBuffer, &tBuffer);
                        
                        tArgumentsCount--;
                    }
                    
                    break;
                }
            }
            
            continue;
            
        }
        
        // Extended Opcode
        
        uint64_t tLength=DWRF_readULEB128(tBuffer, &tBuffer);
        
        if (tLength==0)
        {
            NSLog(@"Unexpected 0 value for extended opcode length");
        }
        
        uint8_t tExtendedOpcode=*tBuffer;
        tBuffer+=sizeof(uint8_t);
        
        tLength-=1;
        
        switch(tExtendedOpcode)
        {
            case DW_LNE_end_sequence:
            {
                tStateMachine.end_sequence=YES;
                
                // Add a row to the matrix
                
                DWRFLineNumberProgramLocation * tLocation=[self locationFromStateMachine:tStateMachine];
                
                NSNumber * tKey=@(tStateMachine.address);
                
                [_locationsAddresses addObject:tKey];
                
                _locationsRegistry[tKey]=tLocation;
                
                tStateMachine=[[DWRFLineNumberProgramStateMachine alloc] initWithStmt:_header.defaultIsStmt];
                
                break;
            }
                
            case DW_LNE_set_address:
            {
                if (tLength==4) // 32 bits
                {
                    tStateMachine.address=*((uint32_t *)tBuffer);
                    tBuffer+=sizeof(uint32_t);
                }
                else    // 64 bits
                {
                    tStateMachine.address=*((uint64_t *)tBuffer);
                    tBuffer+=sizeof(uint64_t);
                }
                
                tStateMachine.op_index=0;
                
                break;
            }
            case DW_LNE_define_file:
            {
                DWRFLineNumberProgramHeaderFileNameEntry * tFileNameEntry=[DWRFLineNumberProgramHeaderFileNameEntry new];
                
                tFileNameEntry.filePath=[NSString stringWithUTF8String:(const char *)tBuffer];
                
                tFileNameEntry.directoryIndex=DWRF_readULEB128(tBuffer, &tBuffer);
                
                tFileNameEntry.lastModificationDate=DWRF_readULEB128(tBuffer, &tBuffer);
                
                tFileNameEntry.fileSize=DWRF_readULEB128(tBuffer, &tBuffer);
                
                
                [_header.fileEntries addObject:tFileNameEntry];
                
                break;
            }
            case DW_LNE_set_discriminator:
                
                tStateMachine.discriminator=DWRF_readULEB128(tBuffer, &tBuffer);
                
                break;
                
            default:
                
                // Unsupported Extended opcode
                
                tBuffer+=tLength;
                
                break;
        }
    }
    
    return YES;
}

- (DWRFLineNumberProgramLocation *)locationForMachineInstructionAddress:(uint64_t)inMachineInstructionAddress
{
    if (_locationsAddresses==nil)
    {
        // We need to build the list of addresses first
        
        if ([self runProgram]==NO)
            return nil;
    }
    
    if (_locationsAddresses.count==0)
        return nil;
    
    NSNumber * tKey=_locationsAddresses.firstObject;
    
    if (inMachineInstructionAddress<[tKey unsignedLongValue])
        return nil;
    
    for(NSNumber * tLocationAddressNumber in _locationsAddresses)
    {
        uint64_t tLocationAddress=[tLocationAddressNumber unsignedLongValue];
        
        if (inMachineInstructionAddress<tLocationAddress)
            break;
        
        tKey=tLocationAddressNumber;
        
        if (inMachineInstructionAddress==tLocationAddress)
            break;
    }
    
    
    DWRFLineNumberProgramLocation * tLocation=_locationsRegistry[tKey];
    
    return tLocation;
}



- (DWRFLineNumberProgramLocation *)locationFromStateMachine:(DWRFLineNumberProgramStateMachine *)inStateMachine
{
    DWRFLineNumberProgramLocation * tLocation=[DWRFLineNumberProgramLocation new];
    
    tLocation.machineInstructionAddress=inStateMachine.address;
    
    DWRFLineNumberProgramHeaderFileNameEntry * tEntry=_header.fileEntries[inStateMachine.file-1];
    
    NSString * tFileName=tEntry.filePath;
    
    if (tEntry.directoryIndex==0)
    {
    }
    else
    {
        NSString * tDirectoryPath=_header.includeDirectories[tEntry.directoryIndex-1];
        
        tFileName=[tDirectoryPath stringByAppendingPathComponent:tFileName];
    }
    
    tLocation.fileName=[tFileName copy];
    tLocation.lineNumber=inStateMachine.line;
    tLocation.columnNumber=inStateMachine.column;
    
    return tLocation;
}

@end

@interface DWRFSection_debug_line ()
{
    NSData * _cachedData;
    
    NSMutableDictionary<NSNumber *,DWRFLineNumberProgram *> * _cachedLineNumberPrograms;
}

@end

@implementation DWRFSection_debug_line

- (instancetype)initWithData:(NSData *)inData
{
    if (inData==nil)
        return nil;
    
    self=[super init];
    
    if (self!=nil)
    {
        _cachedData=inData;
        
        _cachedLineNumberPrograms=[NSMutableDictionary dictionary];
    }
    
    return self;
}

#pragma mark -

- (DWRFLineNumberProgram *)lineNumberProgramAtOffset:(uint64_t)inOffset
{
    DWRFLineNumberProgram * tLineNumberProgram=_cachedLineNumberPrograms[@(inOffset)];
    
    if (tLineNumberProgram!=nil)
        return tLineNumberProgram;
    
    uint8_t * tBufferPtr=(uint8_t *)_cachedData.bytes;
    
    tLineNumberProgram=[[DWRFLineNumberProgram alloc] initWithBuffer:tBufferPtr+inOffset /*fileObject:self.fileObject outBuffer:&tBufferPtr*/];
    
    if (tLineNumberProgram!=nil)
        _cachedLineNumberPrograms[@(inOffset)]=tLineNumberProgram;
    
    return tLineNumberProgram;
}

@end
