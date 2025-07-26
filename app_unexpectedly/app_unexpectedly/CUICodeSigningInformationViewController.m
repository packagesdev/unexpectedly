/*
 Copyright (c) 2025, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CUICodeSigningInformationViewController.h"
#import "NSDictionary+WBExtensions.h"

@interface IPSCodeSigningInfo (UI)

@property (nonatomic, readonly) NSString *validationCategoryDisplayString;

@end


@implementation IPSCodeSigningInfo (UI)

- (NSString *)validationCategoryDisplayString
{
	switch(self.validationCategory)
	{
		case IPSCodeSigningValidationCategoryPlatform:
			return NSLocalizedStringFromTable(@"",@"CodeSigning",@"");
			
		case IPSCodeSigningValidationCategoryTestFlight:
			return NSLocalizedStringFromTable(@"TestFlight",@"CodeSigning",@"");
			
		case IPSCodeSigningValidationCategoryDevelopment:
			return NSLocalizedStringFromTable(@"Development",@"CodeSigning",@"");
			
		case IPSCodeSigningValidationCategoryAppStore:
			return NSLocalizedStringFromTable(@"AppStore",@"CodeSigning",@"");
			
		case IPSCodeSigningValidationCategoryEnterprise:
			return NSLocalizedStringFromTable(@"Enterprise",@"CodeSigning",@"");
			
		case IPSCodeSigningValidationCategoryDeveloperID:
			return NSLocalizedStringFromTable(@"Developer ID",@"CodeSigning",@"");

		case IPSCodeSigningValidationCategoryNone:
			return NSLocalizedStringFromTable(@"None",@"CodeSigning",@"");
	}
	
	return @"-";
}

@end

@interface CUICodeSigningInformationViewController ()
{
	IPSCodeSigningInfo * _info;
	
	IBOutlet NSTextField * _identifierTextField;
	IBOutlet NSTextField * _teamIdentifierTextField;
	
	IBOutlet NSTextField * _validationCategoryTextField;
	
	IBOutlet NSTextField * _flagsRichTextField;
	
	IBOutlet NSTextField * _trustLevelTextField;
}

@end

@implementation CUICodeSigningInformationViewController

+ (NSDictionary <NSString *, NSNumber *> *)flagsToLocalizedNameDictionary
{
	static dispatch_once_t onceToken;
	static NSDictionary <NSString *, NSNumber *> * sConversionDictionary=nil;
	
	dispatch_once(&onceToken, ^{
		
		NSURL * tResourceURL=[[NSBundle bundleForClass:self] URLForResource:@"CodeSigningFlags" withExtension:@"plist"];
		NSError * tError;
		
		sConversionDictionary=[[NSDictionary alloc] initWithContentsOfURL:tResourceURL error:&tError];
		
		if (sConversionDictionary==nil)
			NSLog(@"Could not get the list of codesigning flags: %@",tError);
	});
	
	return sConversionDictionary;
}

- (instancetype)initWithCodeSigningInfo:(IPSCodeSigningInfo *)inCodeSigningInfo
{
	self=[super init];
	
	if (self!=nil)
	{
		_info=[inCodeSigningInfo copy];
	}
	
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	_identifierTextField.stringValue=_info.identifier ?: @"-";
	_teamIdentifierTextField.stringValue=_info.teamIdentifier ?: @"-";
	_validationCategoryTextField.stringValue=_info.validationCategoryDisplayString;
	_flagsRichTextField.attributedStringValue=[self codeSigningFlagsDisplayString];
	_trustLevelTextField.stringValue=[NSString stringWithFormat:@"0x%x",_info.trustLevel];
}

#pragma mark -

- (NSAttributedString *)codeSigningFlagsDisplayString
{
	NSMutableAttributedString * tMutableAttributedString=[[NSMutableAttributedString alloc] initWithString:@""];
	
	NSDictionary <NSString *, NSNumber *> *tFlagsToLocalizedNameDictionary = [CUICodeSigningInformationViewController flagsToLocalizedNameDictionary];
	static dispatch_once_t onceToken;
	static NSArray <NSString *> * sAllFlags=nil;
	
	dispatch_once(&onceToken, ^{
		sAllFlags=[tFlagsToLocalizedNameDictionary.allKeys sortedArrayUsingSelector:@selector(compare:)];
	});
	
	BOOL tFirstLine=YES;
	NSAttributedString * tNewLine=[[NSAttributedString alloc] initWithString:@"\n"
																  attributes:nil];
	BOOL tShouldIncreaseContrast=NSWorkspace.sharedWorkspace.accessibilityDisplayShouldIncreaseContrast;
	NSFont * tSystemFont=[NSFont systemFontOfSize:NSFont.systemFontSize];;
	NSFont * tBoldSystemFont=[NSFont boldSystemFontOfSize:NSFont.systemFontSize];
	
	for(NSString * tKey in sAllFlags)
	{
		if (tFirstLine==NO)
			[tMutableAttributedString appendAttributedString:tNewLine];
		else
			tFirstLine=NO;
		
		NSNumber * tFlagNumber=tFlagsToLocalizedNameDictionary[tKey];
		BOOL tIsFlagSet=((tFlagNumber.unsignedIntValue & _info.flags)!=0);
		NSDictionary * tAttributes;
		
		if (tIsFlagSet==YES)
		{
			NSFont * tFont;
			
			if (tShouldIncreaseContrast==YES)
				tFont = tBoldSystemFont;
			else
				tFont = tSystemFont;
			
			tAttributes = @{
							NSForegroundColorAttributeName : NSColor.labelColor,
							NSFontAttributeName : tFont
							};
		}
		else
		{
			tAttributes = @{
							NSForegroundColorAttributeName : NSColor.tertiaryLabelColor,
							NSFontAttributeName : tSystemFont
							};
		}
		
		NSAttributedString * tAttributedLine=[[NSAttributedString alloc] initWithString:tKey
																			 attributes:tAttributes];
		
		[tMutableAttributedString appendAttributedString:tAttributedLine];
	}
	
	return tMutableAttributedString;
}

@end
