//
//  CUICodeType.h
//  app_unexpectedly
//
//  Created by stephane on 09/03/2021.
//  Copyright © 2021 Acme, Inc. All rights reserved.
//

#ifndef CUICodeType_h
#define CUICodeType_h

typedef NS_ENUM(NSInteger, CUICodeType)
{
    CUICodeTypeUnknown=-1,
    CUICodeTypeX86=0,
    CUICodeTypeX86_64,
    CUICodeTypeARM_64,
    
    CUICodeTypePPC=601,
};

#endif /* CUICodeType_h */
