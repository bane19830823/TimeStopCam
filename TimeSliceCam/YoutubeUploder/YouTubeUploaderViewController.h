//
//  YouTubeUploaderViewController.h
//  TimeSliceCam
//
//  Created by Bane on 2013/04/27.
//  Copyright (c) 2013年 Bane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GData.h"
#import "SingleLineTextCell.h"
#import "DescriptionCell.h"

typedef enum {
    YouTubePublishKindPublic,       //公開
    YouTubePublishKindUnlisted,     //限定公開
    YouTubePublishKindPrivate       //非公開
} YouTubePublishKind;           //YouTubeの公開設定

@class GDataServiceGoogleYouTube;
@class GTMOAuth2Authentication;

@protocol YouTubeUploaderViewControllerDelegate <NSObject>

- (void)YouTubeUploaderDidFinish;

@end

@interface YouTubeUploaderViewController : UIViewController
<UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, UIAlertViewDelegate> {
    IBOutlet UIBarButtonItem *uploadButton;
    IBOutlet UIBarButtonItem *cancelButton;
}

@property (nonatomic, retain) GTMOAuth2Authentication *oAuth;
@property (nonatomic, retain) GDataServiceGoogleYouTube *youtubeService;
@property (nonatomic, retain) NSMutableArray *youtubeCategoryList;
@property (nonatomic, retain) NSString *videoFilePath;
@property (nonatomic, retain) NSData *videoData;
@property (nonatomic, retain) GDataServiceTicket *mUploadTicket;
@property (nonatomic, retain) NSURL *mUploadLocationURL;
@property (nonatomic, assign) YouTubePublishKind publishKind;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, assign) NSInteger selectedCategoryIndex;
@property (nonatomic, retain) IBOutlet UIView *pickerBaseView;
@property (nonatomic, retain) IBOutlet UIPickerView *categoryPicker;
@property (nonatomic, assign) BOOL isShowingPicker;
@property (nonatomic, retain) NSString *googleMailAddress;
@property (nonatomic, assign) id <YouTubeUploaderViewControllerDelegate> delegate;

//TableViewCell
@property (nonatomic, retain) SingleLineTextCell *titleCell;
@property (nonatomic, retain) DescriptionCell *descriptionCell;
@property (nonatomic, retain) SingleLineTextCell *tagsCell;
@property (nonatomic, retain) UITableViewCell *categoryCell;
@property (nonatomic, retain) UITableViewCell *publicCell;
@property (nonatomic, retain) UITableViewCell *unlistedCell;
@property (nonatomic, retain) UITableViewCell *privateCell;
@property (nonatomic, retain) UITableViewCell *accountCell;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
authObject:(GTMOAuth2Authentication *)auth
videoFilePath:(NSString *)filePath
videoData:(NSData *)videoData;

- (IBAction)closePicker:(id)sender;

@end
