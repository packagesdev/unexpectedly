/*
 Copyright (c) 2020-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUIBinaryImage+UI.h"

NSString * const CUIBinaryImageGroupAppKitUIKit=@"AppKit/UIKit";
NSString * const CUIBinaryImageGroupAudioSpeech=@"Audio/Speech";
NSString * const CUIBinaryImageGroupDatabaseStorage=@"Database/Storage";
NSString * const CUIBinaryImageGroupFoundation=@"Foundation";
NSString * const CUIBinaryImageGroupGenericUncategorized=@"Generic/Uncategorized";
NSString * const CUIBinaryImageGroupGraphics=@"Graphics";
NSString * const CUIBinaryImageGroupLanguages=@"Languages";
NSString * const CUIBinaryImageGroupNetworkIO=@"Network or I/O";
NSString * const CUIBinaryImageGroupOtherFrameworks=@"Other frameworks";
NSString * const CUIBinaryImageGroupSecurity=@"Security";
NSString * const CUIBinaryImageGroupSystem=@"System";
NSString * const CUIBinaryImageGroupUserCode=@"User Code";
NSString * const CUIBinaryImageGroupWebInternet=@"Web/Internet";


@implementation CUIBinaryImage (UI)

+ (NSString *)binaryImageGroupForIdentifier:(NSString *)inIdentifier
{
    if (inIdentifier==nil)
        return CUIBinaryImageGroupGenericUncategorized;
    
    static NSDictionary * sGroupRegistry=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sGroupRegistry=@{
                         
                         // Application UI
                         
                         @"libswiftAppKit.dylib":CUIBinaryImageGroupAppKitUIKit,
                         
                         @"com.apple.AppKit":CUIBinaryImageGroupAppKitUIKit,
                         @"com.apple.UIKit":CUIBinaryImageGroupAppKitUIKit,
                         
                         // Audio Speech
                         
                         @"libswiftCoreAudio.dylib":CUIBinaryImageGroupAudioSpeech,
                         
                         @"com.apple.audio.CoreAudio":CUIBinaryImageGroupAudioSpeech,
                         @"com.apple.audio.AppleHDAHALPlugIn":CUIBinaryImageGroupAudioSpeech,
                         @"com.apple.audio.AVFAudio":CUIBinaryImageGroupAudioSpeech,
                         @"com.apple.audio.toolbox.AudioToolbox":CUIBinaryImageGroupAudioSpeech,
                         @"com.apple.audio.units.AudioUnit":CUIBinaryImageGroupAudioSpeech,
                         
                         @"com.apple.speech.recognition.framework":CUIBinaryImageGroupAudioSpeech,
                         @"com.apple.speech.synthesis.framework":CUIBinaryImageGroupAudioSpeech,
                         @"com.apple.SpeechRecognitionCore":CUIBinaryImageGroupAudioSpeech,
                         
                         // Database
                         
                         @"libswiftCoreData.dylib":CUIBinaryImageGroupDatabaseStorage,
                         
                         @"com.apple.CoreData":CUIBinaryImageGroupDatabaseStorage,
                         @"libsqlite3.dylib":CUIBinaryImageGroupDatabaseStorage,
                         
                         // Foundation
                         
                         @"libswiftCoreFoundation.dylib":CUIBinaryImageGroupFoundation,
                         @"libswiftFoundation.dylib":CUIBinaryImageGroupFoundation,
                         
                         @"com.apple.Foundation":CUIBinaryImageGroupFoundation,
                         @"com.apple.CoreFoundation":CUIBinaryImageGroupFoundation,
                         
                         // Graphics
                         
                         @"libswiftAVFoundation.dylib":CUIBinaryImageGroupGraphics,
                         @"libswiftCoreGraphics.dylib":CUIBinaryImageGroupGraphics,
                         @"libswiftCoreImage.dylib":CUIBinaryImageGroupGraphics,
                         @"libswiftMetal.dylib":CUIBinaryImageGroupGraphics,
                         @"libswiftQuartzCore.dylib":CUIBinaryImageGroupGraphics,
                         
                         @"com.apple.ApplicationServices.ATS":CUIBinaryImageGroupGraphics,
                         
                         @"com.apple.opencl":CUIBinaryImageGroupGraphics,
                         
                         @"com.apple.IOSurface":CUIBinaryImageGroupGraphics,
                         
                         @"com.apple.avfoundation":CUIBinaryImageGroupGraphics,
                         @"com.apple.AVKit":CUIBinaryImageGroupGraphics,
                         @"com.apple.ColorSync":CUIBinaryImageGroupGraphics,
                         @"com.apple.ColorSyncLegacy":CUIBinaryImageGroupGraphics,
                         @"com.apple.CoreGraphics":CUIBinaryImageGroupGraphics,
                         @"com.apple.CoreImage":CUIBinaryImageGroupGraphics,
                         @"com.apple.ImageCapture":CUIBinaryImageGroupGraphics,
                         @"com.apple.imageCaptureCore":CUIBinaryImageGroupGraphics,
                         @"com.apple.ImageIO.framework":CUIBinaryImageGroupGraphics,
                         
                         @"com.apple.CoreMedia":CUIBinaryImageGroupGraphics,
                         @"com.apple.CoreMediaAccessibility":CUIBinaryImageGroupGraphics,
                         @"com.apple.CoreMediaAuthoring":CUIBinaryImageGroupGraphics,
                         @"com.apple.CoreMediaIO":CUIBinaryImageGroupGraphics,
                         @"com.apple.CoreMediaKit":CUIBinaryImageGroupGraphics,
                         @"com.apple.MediaPlayer":CUIBinaryImageGroupGraphics,
                         @"com.apple.MediaToolbox":CUIBinaryImageGroupGraphics,
                         @"com.apple.CoreText":CUIBinaryImageGroupGraphics,
                         @"com.apple.CoreVideo":CUIBinaryImageGroupGraphics,
                         @"com.apple.VideoToolbox":CUIBinaryImageGroupGraphics,
                         
                         @"com.apple.opengl":CUIBinaryImageGroupGraphics,
                         @"com.apple.QuartzCore":CUIBinaryImageGroupGraphics,
                         @"libGL.dylib":CUIBinaryImageGroupGraphics,
                         @"libGLImage.dylib":CUIBinaryImageGroupGraphics,
                         @"libGLU.dylib":CUIBinaryImageGroupGraphics,
                         
                         @"com.apple.QD":CUIBinaryImageGroupGraphics,
                         
                         @"libmetal_timestamp.dylib":CUIBinaryImageGroupGraphics,
                         @"com.apple.gpusw.MetalTools":CUIBinaryImageGroupGraphics,
                         
                         @"com.apple.PDFKit":CUIBinaryImageGroupGraphics,
                         @"com.apple.CorePDF":CUIBinaryImageGroupGraphics,
                         
                         @"com.apple.AppleJPEG":CUIBinaryImageGroupGraphics,
                         
                         @"libGIF.dylib":CUIBinaryImageGroupGraphics,
                         @"libJP2.dylib":CUIBinaryImageGroupGraphics,
                         @"libJPEG.dylib":CUIBinaryImageGroupGraphics,
                         @"libPng.dylib":CUIBinaryImageGroupGraphics,
                         @"libRadiance.dylib":CUIBinaryImageGroupGraphics,
                         @"libTIFF.dylib":CUIBinaryImageGroupGraphics,
                         
                         // Languages
                         
                         @"libswiftObjectiveC.dylib":CUIBinaryImageGroupLanguages,
                         
                         // Network
                         
                         @"com.apple.CFNetwork":CUIBinaryImageGroupNetworkIO,
                         @"libnetwork.dylib":CUIBinaryImageGroupNetworkIO,
                         @"libsystem_networkextension.dylib":CUIBinaryImageGroupNetworkIO,
                         @"libapple_nghttp2.dylib":CUIBinaryImageGroupNetworkIO,
                         
                         // Security
                         
                         @"com.apple.Kerberos":CUIBinaryImageGroupSecurity,
                         @"libcommonCrypto.dylib":CUIBinaryImageGroupSecurity,
                         @"libcorecrypto.dylib":CUIBinaryImageGroupSecurity,
                         
                         // System
                         
                         @"libdyld.dylib":CUIBinaryImageGroupSystem,
                         @"libdispatch.dylib":CUIBinaryImageGroupSystem,
                         
                         // Web Internet
                         
                         @"com.apple.JavaScriptCore":CUIBinaryImageGroupWebInternet,
                         @"com.apple.WebCore":CUIBinaryImageGroupWebInternet,
                         @"com.apple.WebKitLegacy":CUIBinaryImageGroupWebInternet,
                         @"com.apple.WebKit":CUIBinaryImageGroupWebInternet,
                         @"libwebrtc.dylib":CUIBinaryImageGroupWebInternet,
                         };
        
    });
    
    NSString * tBinaryImageGroup=sGroupRegistry[inIdentifier];
    
    if (tBinaryImageGroup!=nil)
        return tBinaryImageGroup;
    
    // Try to figure out differently
    
    if ([inIdentifier hasPrefix:@"libc++"]==YES ||
        [inIdentifier hasPrefix:@"libobjc"]==YES)
        return CUIBinaryImageGroupLanguages;
    
    if ([inIdentifier hasPrefix:@"com.apple.Metal"]==YES)
        return CUIBinaryImageGroupGraphics;
    
    if ([inIdentifier hasPrefix:@"com.apple.security"]==YES)
        return CUIBinaryImageGroupSecurity;
    
    if ([inIdentifier hasPrefix:@"com.apple."]==YES)
        return CUIBinaryImageGroupOtherFrameworks;
    
    if ([inIdentifier hasPrefix:@"libsystem_"]==YES)
        return CUIBinaryImageGroupSystem;
    
    return CUIBinaryImageGroupGenericUncategorized;
}

+ (NSImage *)iconForBinaryImageGroup:(NSString *)inBinaryImageGroup
{
    if (inBinaryImageGroup==nil)
        inBinaryImageGroup=CUIBinaryImageGroupGenericUncategorized;
    
    static NSDictionary * sIconsRegistry=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        
        sIconsRegistry=@{
                         
                         CUIBinaryImageGroupAppKitUIKit:[NSImage imageNamed:@"call-appkit"],
                         CUIBinaryImageGroupAudioSpeech:[NSImage imageNamed:@"call-audiospeech"],
                         CUIBinaryImageGroupDatabaseStorage:[NSImage imageNamed:@"call-database"],
                         CUIBinaryImageGroupFoundation:[NSImage imageNamed:@"call-foundation"],
                         CUIBinaryImageGroupGenericUncategorized:[NSImage imageNamed:@"call-generic"],
                         CUIBinaryImageGroupGraphics:[NSImage imageNamed:@"call-graphics"],
                         CUIBinaryImageGroupLanguages:[NSImage imageNamed:@"call-languages"],
                         CUIBinaryImageGroupNetworkIO:[NSImage imageNamed:@"call-network"],
                         CUIBinaryImageGroupOtherFrameworks:[NSImage imageNamed:@"call-framework"],
                         CUIBinaryImageGroupSecurity:[NSImage imageNamed:@"call-security"],
                         CUIBinaryImageGroupSystem:[NSImage imageNamed:@"call-system"],
                         CUIBinaryImageGroupUserCode:[NSImage imageNamed:@"call-usercode"],
                         CUIBinaryImageGroupWebInternet:[NSImage imageNamed:@"call-webinternet"],
                         };
        
    });
    
    NSImage * tImage=sIconsRegistry[inBinaryImageGroup];
    
    if (tImage!=nil)
        return tImage;
    
    return sIconsRegistry[CUIBinaryImageGroupGenericUncategorized];
}

+ (NSColor *)colorForBinaryImageGroup:(NSString *)inBinaryImageGroup
{
    if (inBinaryImageGroup==nil)
        inBinaryImageGroup=CUIBinaryImageGroupGenericUncategorized;
    
    static NSDictionary * sColorsRegistry=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        
        sColorsRegistry=@{
                          
                          CUIBinaryImageGroupAppKitUIKit:[NSColor colorWithDeviceRed:176/255.0 green:155/255.0 blue:202/255.0 alpha:1.0],
                          CUIBinaryImageGroupAudioSpeech:[NSColor colorWithDeviceRed:169/255.0 green:184/255.0 blue:192/255.0 alpha:1.0],
                          CUIBinaryImageGroupDatabaseStorage:[NSColor colorWithDeviceRed:212/255.0 green:194/255.0 blue:87/255.0 alpha:1.0],
                          CUIBinaryImageGroupFoundation:[NSColor colorWithDeviceRed:185/255.0 green:181/255.0 blue:160/255.0 alpha:1.0],
                          CUIBinaryImageGroupGenericUncategorized:[NSColor colorWithDeviceRed:167/255.0 green:146/255.0 blue:126/255.0 alpha:1.0],
                          CUIBinaryImageGroupGraphics:[NSColor colorWithDeviceRed:155/255.0 green:152/255.0 blue:210/255.0 alpha:1.0],
                          CUIBinaryImageGroupLanguages:[NSColor colorWithDeviceRed:158/255.0 green:111/255.0 blue:147/255.0 alpha:1.0],
                          CUIBinaryImageGroupNetworkIO:[NSColor colorWithDeviceRed:215/255.0 green:137/255.0 blue:101/255.0 alpha:1.0],
                          CUIBinaryImageGroupOtherFrameworks:[NSColor colorWithDeviceRed:190/255.0 green:154/255.0 blue:150/255.0 alpha:1.0],
                          CUIBinaryImageGroupSecurity:[NSColor colorWithDeviceRed:85/255.0 green:138/255.0 blue:82/255.0 alpha:1.0],
                          CUIBinaryImageGroupSystem:[NSColor colorWithDeviceRed:201/255.0 green:185/255.0 blue:156/255.0 alpha:1.0],
                          CUIBinaryImageGroupUserCode:[NSColor colorWithDeviceRed:133/255.0 green:168/255.0 blue:210/255.0 alpha:1.0],
                          CUIBinaryImageGroupWebInternet:[NSColor colorWithDeviceRed:106/255.0 green:131/255.0 blue:141/255.0 alpha:1.0],
                          };
        
    });
    
    NSColor * tColor=sColorsRegistry[inBinaryImageGroup];
    
    if (tColor!=nil)
        return tColor;
    
    return sColorsRegistry[CUIBinaryImageGroupGenericUncategorized];
}

+ (NSImage *)iconForIdentifier:(NSString *)inIdentifier
{
    NSString * tBinaryImageGroup=[CUIBinaryImage binaryImageGroupForIdentifier:inIdentifier];
    
    return [CUIBinaryImage iconForBinaryImageGroup:tBinaryImageGroup];
}

+ (NSImage *)iconForPath:(NSString *)inPath
{
    return nil;
}

+ (NSColor *)colorForUserCode
{
    static NSColor * sUserCodeColor=nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
    
        sUserCodeColor=[NSColor colorWithDeviceRed:133/255.0 green:168/255.0 blue:210/255.0 alpha:1.0];
    });
    
    return sUserCodeColor;
}

+ (NSColor *)colorForIdentifier:(NSString *)inIdentifier
{
    NSString * tBinaryImageGroup=[CUIBinaryImage binaryImageGroupForIdentifier:inIdentifier];
    
    return [CUIBinaryImage colorForBinaryImageGroup:tBinaryImageGroup];
}

@end
