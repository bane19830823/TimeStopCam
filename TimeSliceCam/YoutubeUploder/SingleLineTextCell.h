//
//  TitleCell.h
//  TimeSliceCam
//
//  Created by Bane on 2013/04/28.
//  Copyright (c) 2013年 Bane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SingleLineTextCell : UITableViewCell <UITextFieldDelegate>

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) IBOutlet UILabel *placeHolderLabel;
@property (nonatomic, retain) IBOutlet UITextField *textField;

- (void)setPlaceHolderText:(NSString *)placeHolderText;

@end
