/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSFileManager+ExtendedAttributes.h"

//#include <fts.h>
//#include <sys/stat.h>
#include <sys/xattr.h>

@implementation NSFileManager (ExtendedAttributes)

+ (id)WB_objectFromData:(NSData *)inData extendedAttributeName:(NSString *)inAttributeName
{
    // A COMPLETER
    
    return inData;
}

- (NSDictionary *)WB_extendedAttributesOfItemAtURL:(NSURL *)inURL error:(NSError *__autoreleasing *)outError
{
    if (inURL==nil || inURL.isFileURL==NO)
        return nil;
    
    return [self WB_extendedAttributesOfItemAtPath:inURL.path error:outError];
}

- (NSDictionary *)WB_extendedAttributesOfItemAtPath:(NSString *)inPath error:(NSError *__autoreleasing *)outError
{
    if (inPath==nil)
        return nil;
    
    const char * tCPath=[inPath fileSystemRepresentation];
    
    if (tCPath==NULL)
    {
        NSLog(@"Unable to get file system representation for path: %@",inPath);
        
        return nil;
    }
    
    int tFileDescriptor=open(tCPath,O_RDONLY|O_NOFOLLOW);
    
    if (tFileDescriptor==-1)
    {
        if (errno==ELOOP)    // Symbolic link
            return [NSDictionary dictionary];
        
        if (outError!=NULL)
        {
            NSError * tUnderlyingError;
            
            switch(errno)
            {
                case EACCES:
                    
                    *outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadNoPermissionError userInfo:nil];
                    return nil;
                    
                case ENOENT:
                    
                    tUnderlyingError=[NSError errorWithDomain:NSPOSIXErrorDomain code:ENOENT userInfo:nil];
                    *outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadNoSuchFileError userInfo:@{NSFilePathErrorKey:inPath,
                                                                                                                    NSUnderlyingErrorKey:tUnderlyingError}];
                    return nil;
                    
                default:
                    
                    *outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
                    return nil;
            }
        }
        
        return nil;
    }
    
    ssize_t tBufferSize=flistxattr(tFileDescriptor,NULL,0,0);
    
    if (tBufferSize==-1)
    {
        if (errno==ENOTSUP)
            return [NSDictionary dictionary];
        
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
        
        close(tFileDescriptor);
        
        return nil;
    }
    
    if (tBufferSize==0)
        return [NSDictionary dictionary];
    
    char * tBuffer=(char *)malloc(tBufferSize*sizeof(char));
    
    if (tBuffer==NULL)
    {
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:ENOMEM userInfo:nil];
        
        close(tFileDescriptor);
        
        return nil;
    }
    
    ssize_t tReadBufferSize=flistxattr(tFileDescriptor, tBuffer, tBufferSize, 0);
    
    if (tReadBufferSize==-1)
    {
        if (errno==ENOTSUP)
        {
            free(tBuffer);
            close(tFileDescriptor);
            return [NSDictionary dictionary];
        }
        
        if (outError!=NULL)
            *outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
        
        free(tBuffer);
        
        close(tFileDescriptor);
        
        return nil;
    }
    
    char * tBufferEnd=tBuffer+tReadBufferSize;
    
    NSMutableDictionary * tExtendedAttributes=[NSMutableDictionary dictionary];
    
    for(char * tAttributeNamePtr=tBuffer;tAttributeNamePtr<tBufferEnd;tAttributeNamePtr+=strlen(tAttributeNamePtr)+1)
    {
        NSString * tAttributeName=[NSString stringWithUTF8String:tAttributeNamePtr];
        
        if (tAttributeName==nil)
        {
            // A COMPLETER
            
            tExtendedAttributes=nil;
            goto extended_attributes_bail;
        }
        
        ssize_t tAttributeBufferSize=fgetxattr(tFileDescriptor,tAttributeNamePtr, NULL, 0, 0, 0);
        
        if (tAttributeBufferSize==-1)
        {
            if (outError!=NULL)
                *outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
            
            tExtendedAttributes=nil;
            goto extended_attributes_bail;
        }
        
        void * tAttributeBuffer=malloc(tAttributeBufferSize*sizeof(uint8_t));
        
        if (tAttributeBuffer==NULL)
        {
            if (outError!=NULL)
                *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:ENOMEM userInfo:nil];
            
            tExtendedAttributes=nil;
            goto extended_attributes_bail;
        }
        
        ssize_t tReadAttributeBufferSize=fgetxattr(tFileDescriptor,tAttributeNamePtr, tAttributeBuffer,tAttributeBufferSize, 0, 0);
        
        if (tReadAttributeBufferSize==-1)
        {
            if (outError!=NULL)
                *outError=[NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
            
            free(tAttributeBuffer);
            tExtendedAttributes=nil;
            goto extended_attributes_bail;
        }
        
        NSData * tData=[NSData dataWithBytesNoCopy:tAttributeBuffer length:tReadAttributeBufferSize];
        
        if (tData==nil)
        {
            // A COMPLETER
            
            free(tAttributeBuffer);
            tExtendedAttributes=nil;
            goto extended_attributes_bail;
        }
        
        id tObject=[NSFileManager WB_objectFromData:tData extendedAttributeName:tAttributeName];
        
        if (tObject==nil)
        {
            if (outError!=NULL)
                *outError=[NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:nil];
            
            tExtendedAttributes=nil;
            goto extended_attributes_bail;
        }
        
        tExtendedAttributes[tAttributeName]=tObject;
    }
    
extended_attributes_bail:
    
    free(tBuffer);
    
    close(tFileDescriptor);
    
    return [tExtendedAttributes copy];
}

@end
