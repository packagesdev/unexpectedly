//
//  CUIAboutBoxWindow.m
//  Unexpectedly
//
//  Created by stephane on 09/04/2021.
//  Copyright © 2021 Acme, Inc. All rights reserved.
//

#import "CUIAboutBoxWindow.h"

NSString * const CUIOptionKeyStateDidChangeNotification=@"CUIOptionKeyStateDidChangeNotification";

NSString * const CUIOptionKeyState=@"CUIOptionKeyState";

@interface CUIAboutBoxWindow ()
{
    BOOL _optionKeyDown;
}

@end

@implementation CUIAboutBoxWindow

- (void)becomeKeyWindow
{
    NSEvent * tEvent=[NSApp currentEvent];
    
    if (tEvent!=nil)
    {
        NSUInteger tModifierFlags=tEvent.modifierFlags;
        
        BOOL isDown=((tModifierFlags & NSEventModifierFlagOption) == NSEventModifierFlagOption);
        
        if (isDown!=_optionKeyDown)
        {
            _optionKeyDown=isDown;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:CUIOptionKeyStateDidChangeNotification
                                                                object:self
                                                              userInfo:@{CUIOptionKeyState:@(_optionKeyDown)}];
        }
    }
    
    [super becomeKeyWindow];
}

- (void)resignKeyWindow
{
    if (_optionKeyDown==YES)
    {
        _optionKeyDown=NO;
        
        // Post Notification
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CUIOptionKeyStateDidChangeNotification
                                                            object:self
                                                          userInfo:@{CUIOptionKeyState:@(_optionKeyDown)}];
    }
    
    [super resignKeyWindow];
}

- (void)flagsChanged:(NSEvent *)inEvent
{
    if (inEvent==nil)
        return;
    
    NSUInteger tModifierFlags=inEvent.modifierFlags;
    
    BOOL isDown=((tModifierFlags & NSEventModifierFlagOption) == NSEventModifierFlagOption);
    
    if (isDown!=_optionKeyDown)
    {
        _optionKeyDown=isDown;
        
        // Post Notification
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CUIOptionKeyStateDidChangeNotification
                                                            object:self
                                                          userInfo:@{CUIOptionKeyState:@(_optionKeyDown)}];
    }
}

@end
