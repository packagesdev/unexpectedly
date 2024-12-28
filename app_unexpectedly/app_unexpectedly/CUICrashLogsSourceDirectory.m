/*
 Copyright (c) 2020-2022 Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLogsSourceDirectory.h"

#import "CUICrashLogsProvider.h"

void mycallback(
                 ConstFSEventStreamRef streamRef,
                 void *clientCallBackInfo,
                 size_t numEvents,
                 void * eventPaths,
                 const FSEventStreamEventFlags eventFlags[],
                const FSEventStreamEventId eventIds[]);

@interface CUICrashLogsSourceDirectory ()
{
    NSArray * _crashLogs;
    
    FSEventStreamRef _eventStreamRef;
    
    BOOL _collectRetired;
}

- (void)handleFileSystemEventIDs:(const FSEventStreamEventId[])inEventIDs paths:(NSArray *)inEventsPaths flags:(const FSEventStreamEventFlags[])inFlags;

@end

@implementation CUICrashLogsSourceDirectory

- (BOOL)initCommonWithError:(NSError **)outError
{
    NSArray * tCrashLogs=[[CUICrashLogsProvider defaultProvider] crashLogsForDirectory:self.path options:(_collectRetired==YES) ? CUICrashLogsProviderCollectRetired : 0 error:outError];
    
    if (tCrashLogs==nil)
        return NO;
    
    _crashLogs=tCrashLogs;
    
    NSArray * tMonitoredPaths=nil;
    
    if (_collectRetired == YES)
    {
        tMonitoredPaths=@[self.path, [self.path stringByAppendingPathComponent:CUIRetiredPathComponent]];
    }
    else
    {
        tMonitoredPaths=@[self.path];
    }
    
    FSEventStreamContext context;
    context.info = (__bridge void *)self;     // !!!
    context.version = 0;
    context.retain = NULL;
    context.release = NULL;
    context.copyDescription = NULL;
    
    CFAbsoluteTime latency = 3.0; /* Latency in seconds */
    
    /* Create the stream, passing in a callback */
    _eventStreamRef = FSEventStreamCreate(kCFAllocatorDefault,&mycallback,&context,(__bridge CFArrayRef)tMonitoredPaths,kFSEventStreamEventIdSinceNow,latency,kFSEventStreamCreateFlagWatchRoot+kFSEventStreamCreateFlagUseCFTypes);
    
    FSEventStreamScheduleWithRunLoop(_eventStreamRef, CFRunLoopGetCurrent(),kCFRunLoopDefaultMode);
    
    FSEventStreamStart(_eventStreamRef);
    
    return YES;
}

- (instancetype)initWithRepresentation:(NSDictionary *)inRepresentation
{
    self=[super initWithRepresentation:inRepresentation];
    
    if (self!=nil)
    {
        if ([self initCommonWithError:NULL]==NO)
            return nil;
    }
    
    return self;
}

- (instancetype)initWithContentsOfFileSystemItemAtPath:(NSString *)inPath error:(NSError **)outError
{
    self = [super initWithContentsOfFileSystemItemAtPath:inPath error:outError];
    
    if (self!=nil)
    {
        if ([self initCommonWithError:NULL]==NO)
            return nil;
    }
    
    return self;
}

- (instancetype)initWithContentsOfFileSystemItemAtPath:(NSString *)inPath collectRetired:(BOOL)inCollectRetired error:(NSError **)outError
{
    self=[super initWithContentsOfFileSystemItemAtPath:inPath error:outError];
    
    if (self!=nil)
    {
        _collectRetired=inCollectRetired;
        
        if ([self initCommonWithError:outError]==NO)
            return nil;
    }
    
    return self;
}

- (void)dealloc
{
    if (_eventStreamRef!=NULL)
    {
        FSEventStreamStop(_eventStreamRef);
        FSEventStreamInvalidate(_eventStreamRef);
    
        FSEventStreamRelease(_eventStreamRef);
    }
}

#pragma mark -

- (CUICrashLogsSourceType)type
{
    return CUICrashLogsSourceTypeDirectory;
}

- (NSString *)name
{
    return self.path.lastPathComponent;
}

- (NSArray *)crashLogs
{
    return _crashLogs;
}

#pragma mark -

- (BOOL)containsCrashLogsFileAtPath:(NSString *)inPath
{
    if ([inPath rangeOfString:self.path options:NSCaseInsensitiveSearch].location!=0)
        return NO;
    
    for(CUIRawCrashLog * tCrashLog in self.crashLogs)
    {
        NSString * tCrashLogFilePath=tCrashLog.crashLogFilePath;
        
        if (tCrashLogFilePath==nil)
            continue;
        
        if ([tCrashLogFilePath isEqualToString:inPath]==YES)
            return YES;
    }
    
    return NO;
}

#pragma mark -

- (void)handleFileSystemEventIDs:(const FSEventStreamEventId[])inEventIDs paths:(NSArray *)inEventsPaths flags:(const FSEventStreamEventFlags[])inFlags
{
    // Check if the directory stil exists
    
    if ((inFlags[0] & kFSEventStreamEventFlagRootChanged)==kFSEventStreamEventFlagRootChanged)
    {
        // A COMPLETER
        
        /*BOOL tIsDirectory;
         
         if ([[NSFileManager defaultManager] fileExistsAtPath:_directoryPath isDirectory:&tIsDirectory]==NO || tIsDirectory==NO)
         {
         // A COMPLETER
         
         return;
         }*/
        
        _crashLogs=[[CUICrashLogsProvider defaultProvider] crashLogsForDirectory:self.path options:(_collectRetired==YES) ? CUICrashLogsProviderCollectRetired : 0 error:NULL];;
    }
    else
    {
        // Refresh the list of crash logs
    
        NSArray * tCrashLogs=[[CUICrashLogsProvider defaultProvider] crashLogsForDirectory:self.path options:(_collectRetired==YES) ? CUICrashLogsProviderCollectRetired : 0 error:NULL];
        
        if (tCrashLogs==nil)
            return;
        
        _crashLogs=tCrashLogs;
    }
    
    [NSNotificationCenter.defaultCenter postNotificationName:CUICrashLogsSourceDidUpdateSourceNotification object:self];
}

@end

void mycallback(ConstFSEventStreamRef streamRef,void * inInfo,size_t inNumEvent,void * inEventPaths,const FSEventStreamEventFlags inEventFlags[],const FSEventStreamEventId inEventIDs[])
{
    NSArray * tEventPaths=(__bridge NSArray *)inEventPaths;
    
    CUICrashLogsSourceDirectory * tSourceDirectory=(__bridge CUICrashLogsSourceDirectory *)inInfo;
    
    [tSourceDirectory handleFileSystemEventIDs:inEventIDs paths:tEventPaths flags:inEventFlags];
}
