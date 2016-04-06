//
//  DiscriptionCell.h
//  TimeSliceCam
//
//  Created by Bane on 2013/04/28.
//  Copyright (c) 2013年 Bane. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DescriptionCell : UITableViewCell <UITextViewDelegate>

@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UILabel *placeHolderLabel;

- (void)setPlaceHolderText:(NSString *)placeHolderText;

@end
