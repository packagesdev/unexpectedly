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
			return @"";
			
		case IPSCodeSigningValidationCategoryTestFlight:
			return @"TestFlight";
			
		case IPSCodeSigningValidationCategoryDevelopment:
			return @"Development";
			
		case IPSCodeSigningValidationCategoryAppStore:
			return @"AppStore";
			
		case IPSCodeSigningValidationCategoryEnterprise:
			return @"Enterprise";
			
		case IPSCodeSigningValidationCategoryDeveloperID:
			return @"Developer ID";

		case IPSCodeSigningValidationCategoryNone:
			return @"None";
	}
	
	return @"-";
}

@end

@interface CUICodeSigningInformationViewController () <NSTableViewDataSource, NSTableViewDelegate>
{
	IPSCodeSigningInfo * _info;
	
	IBOutlet NSTextField * _identifierTextField;
	IBOutlet NSTextField * _teamIdentifierTextField;
	
	IBOutlet NSTextField * _validationCategoryTextField;
	
	IBOutlet NSTableView * _flagsTableView;
	
	IBOutlet NSTextField * _trustLevelTextField;
	
	NSArray <NSString *> * _allFlags;
	
	SecCodeSignatureFlags tet;
}

@end

@implementation CUICodeSigningInformationViewController

+ (NSDictionary <NSString *, NSNumber *> *)flagsToLocalizedNameDictionary
{
	static dispatch_once_t onceToken;
	static NSDictionary <NSString *, NSNumber *> * sConversionDictionary=nil;
	
	dispatch_once(&onceToken, ^{
		
		NSURL * resourceURL=[[NSBundle bundleForClass:self] URLForResource:@"CodeSigningFlags" withExtension:@"plist"];
		
		sConversionDictionary=[[NSDictionary alloc] initWithContentsOfURL:resourceURL error:NULL];	// A COMPLETER
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
	
	_allFlags = [[CUICodeSigningInformationViewController flagsToLocalizedNameDictionary].allKeys sortedArrayUsingSelector:@selector(compare:)];
	
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	_identifierTextField.stringValue=_info.identifier ?: @"-";
	_teamIdentifierTextField.stringValue=_info.teamIdentifier ?: @"-";
	_validationCategoryTextField.stringValue=_info.validationCategoryDisplayString;
	
	_trustLevelTextField.stringValue=[NSString stringWithFormat:@"0x%x",_info.trustLevel];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return _allFlags.count;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)inTableView viewForTableColumn:(NSTableColumn *)inTableColumn row:(NSInteger)inRow
{
	NSString * tTableColumnIdentifier=inTableColumn.identifier;
	NSTableCellView * tTableCellView=[inTableView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
	
	NSString * tKey=_allFlags[inRow];
	NSNumber *flagNumber=[CUICodeSigningInformationViewController flagsToLocalizedNameDictionary][tKey];
	
	BOOL tIsFlagSet=((flagNumber.unsignedIntValue & _info.flags)!=0);
	
	tTableCellView.textField.stringValue=tKey;
	tTableCellView.textField.textColor=(tIsFlagSet==YES) ? [NSColor controlTextColor] : [NSColor disabledControlTextColor];
	
	
	return tTableCellView;
}

@end
