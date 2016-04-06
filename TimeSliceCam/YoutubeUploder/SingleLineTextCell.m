//
//  TitleCell.m
//  TimeSliceCam
//
//  Created by Bane on 2013/04/28.
//  Copyright (c) 2013年 Bane. All rights reserved.
//

#import "SingleLineTextCell.h"

@implementation SingleLineTextCell
@synthesize title = _title;
@synthesize textField = _textField;
@synthesize placeHolderLabel = _placeHolderLabel;

- (void)dealloc {
    self.title = nil;
    self.textField = nil;
    self.placeHolderLabel = nil;
    
    [super dealloc];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setPlaceHolderText:(NSString *)placeHolderText {
    self.placeHolderLabel.text = placeHolderText;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.textField) {
        self.title = textField.text;
    }
    [textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (range.location == 0 && range.length == 0) {
        self.placeHolderLabel.alpha = 0;
    } else if (range.location == 0 && range.length == 1) {
        self.placeHolderLabel.alpha = 1;
    }
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    // ツールバーの作成
    UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    toolBar.barStyle = UIBarStyleBlackOpaque; // スタイルを設定
    [toolBar sizeToFit];
    
    // フレキシブルスペースの作成（Doneボタンを右端に配置したいため）
    UIBarButtonItem *spacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil] autorelease];
    
    // Doneボタンの作成
    UIBarButtonItem *done = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeKeyboard)] autorelease];
    
    // ボタンをToolbarに設定
    NSArray *items = [NSArray arrayWithObjects:spacer, done, nil];
    [toolBar setItems:items animated:YES];
    
    // ToolbarをUITextFieldのinputAccessoryViewに設定
    self.textField.inputAccessoryView = toolBar;
    
    [toolBar release];
    
    return YES;
}

- (void)closeKeyboard {
    [self.textField resignFirstResponder];
}

@end
