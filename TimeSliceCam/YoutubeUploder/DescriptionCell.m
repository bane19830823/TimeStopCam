//
//  DiscriptionCell.m
//  TimeSliceCam
//
//  Created by Bane on 2013/04/28.
//  Copyright (c) 2013年 Bane. All rights reserved.
//

#import "DescriptionCell.h"

@implementation DescriptionCell
@synthesize description = _description;
@synthesize textView = _textView;
@synthesize placeHolderLabel = _placeHolderLabel;

- (void)dealloc {
    self.description = nil;
    self.textView = nil;
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

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
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
    self.textView.inputAccessoryView = toolBar;
    
    [toolBar release];
    
    return YES;
}

- (void)closeKeyboard {
    [self.textView resignFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView == self.textView) {
        self.description = textView.text;
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if (range.location == 0 && range.length == 0) {
        self.placeHolderLabel.alpha = 0;
    } else if (range.location == 0 && range.length == 1) {
        self.placeHolderLabel.alpha = 1;
    }
    return YES;
}

@end
