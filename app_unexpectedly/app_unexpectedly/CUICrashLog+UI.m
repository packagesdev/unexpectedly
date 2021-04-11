/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICrashLog+UI.h"

#import "CUIRawCrashLog+Path.h"

@implementation CUICrashLog (UI)

- (NSImage *)processIcon
{    
    static NSImage * sExecutableBinaryIcon=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sExecutableBinaryIcon=[[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ExecutableBinaryIcon.icns"];
        
    });
    
    NSString * tPath=[self stringByResolvingUSERInPath:self.header.executablePath];
	
	NSString * tMacOSDirectoryPath=tPath.stringByDeletingLastPathComponent;
	
	if ([tMacOSDirectoryPath.lastPathComponent isEqualToString:@"MacOS"]==NO)
		return [[NSWorkspace sharedWorkspace] iconForFile:tPath];
	
	NSString * tContentsDirectoryPath=tMacOSDirectoryPath.stringByDeletingLastPathComponent;
	
	if ([tContentsDirectoryPath.lastPathComponent isEqualToString:@"Contents"]==NO)
		return sExecutableBinaryIcon;
	
	NSDictionary * tDictionary=[NSDictionary dictionaryWithContentsOfFile:[tContentsDirectoryPath stringByAppendingPathComponent:@"Info.plist"]];
	
	if (tDictionary==nil)
		return sExecutableBinaryIcon;
	
	NSString * tExecutableName=tDictionary[@"CFBundleExecutable"];
    
    if ([tExecutableName isEqualToString:tPath.lastPathComponent]==NO)
        return sExecutableBinaryIcon;
    
    NSString * tApplicationIconName=tDictionary[@"CFBundleIconFile"];
	
	if (tApplicationIconName.pathExtension.length==0)
		tApplicationIconName=[tApplicationIconName stringByAppendingPathExtension:@"icns"];
	
	NSString * tIconPath=[[tContentsDirectoryPath stringByAppendingPathComponent:@"Resources"] stringByAppendingPathComponent:tApplicationIconName];
	
	NSImage * tImage=[[NSImage alloc] initWithContentsOfFile:tIconPath];
	
	if (tImage!=nil)
        return tImage;
    
	return [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericApplicationIcon)];
}

- (NSString *)operatingSystemDisplayName
{
    CUIOperatingSystemVersion * tVersion=self.header.operatingSystemVersion;
    
    switch(tVersion.majorVersion)
    {
        case 11:
            
            return @"macOS Big Sur";
            
        default:
            
            break;
    }
    
	NSUInteger tMinorVersion=self.header.operatingSystemVersion.minorVersion;
	
	switch(tMinorVersion)
	{
		case 6:
			
			return @"Mac OS X Snow Leopard";
		
		case 10:
			
			return @"OS X Yosemite";
			
        case 11:
            
            return @"macOS Mavericks";
        
        case 12:
            
            return @"macOS Sierra";
        
        case 13:
            
            return @"macOS High Sierra";
        
        case 14:
            
            return @"macOS Mojave";
        
        case 15:
			
			return @"macOS Catalina";
	}
	
	return @"macOS";
}

@end
