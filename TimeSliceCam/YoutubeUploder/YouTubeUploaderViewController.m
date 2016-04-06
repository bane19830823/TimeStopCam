//
//  YouTubeUploaderViewController.m
//  TimeSliceCam
//
//  Created by Bane on 2013/04/27.
//  Copyright (c) 2013年 Bane. All rights reserved.
//

#import "YouTubeUploaderViewController.h"
#import "GData.h"
#import "GTMOAuth2Authentication.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GDataEntryYouTubeUpload.h"
#import "YouTubeLogoView.h"
#import "SingleLineTextCell.h"
#import "DescriptionCell.h"
#import "GoogleManager.h"
#import "GDataServiceGoogleYouTube.h"


@interface YouTubeUploaderViewController ()
@end

@implementation YouTubeUploaderViewController

@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
           authObject:(GTMOAuth2Authentication *)auth
        videoFilePath:(NSString *)filePath
            videoData:(NSData *)videoData
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.oAuth = auth;
        self.videoFilePath = filePath;
        self.videoData = videoData;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    cancelButton.title = NSLocalizedString(@"Cancel", @"CancelButtonTitle");
    uploadButton.title = NSLocalizedString(@"Publish", @"PublishButtonTitle");
    
    NSArray *tmpArray = [[NSBundle mainBundle] loadNibNamed:@"YouTubeLogoView" owner:self options:nil];
    YouTubeLogoView *logoView = [tmpArray objectAtIndex:0];
    self.tableView.tableHeaderView = logoView;
    
    self.youtubeCategoryList = [[NSMutableArray alloc] initWithCapacity:0];
    
    //youtubeカテゴリーを取得する
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Fetching YouTube Category", @"Fetching YouTube Category")
                         maskType:SVProgressHUDMaskTypeBlack];
    
    [self fetchStandardCategories];
    //初期設定は公開に設定
    self.publishKind = YouTubePublishKindPublic;
    //選択中のカテゴリインデックス
    self.selectedCategoryIndex = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)uploadToYoutube {
    cancelButton.enabled = uploadButton.enabled = NO;
    
    NSURL *url = [GDataServiceGoogleYouTube youTubeUploadURLForUserID:@"default"];
    
    NSString *fileName = [self.videoFilePath lastPathComponent];
    NSLog(@"fileName : %@", fileName);
    
    GDataMediaTitle *title = [GDataMediaTitle textConstructWithString:self.titleCell.title];
    
    GDataMediaCategory *category = [GDataMediaCategory mediaCategoryWithString:[self youtubeCategoryTermWithIndex:self.selectedCategoryIndex]];
    
    [category setScheme:kGDataSchemeYouTubeCategory];
    
    NSArray *categoryArray = [[NSArray alloc] initWithObjects:category, nil];
    
    
    GDataMediaDescription *description = [GDataMediaDescription textConstructWithString:self.descriptionCell.description];
    
    NSArray *keyArray = [self.tagsCell.title componentsSeparatedByString:@","];
    
    GDataMediaKeywords *keywords = [GDataMediaKeywords keywordsWithStrings:keyArray];
        
    self.youtubeService = [self makeYoutubeServiceWithAuth:self.oAuth];
    
    GDataYouTubeMediaGroup *mediaGroup = [GDataYouTubeMediaGroup mediaGroup];
    
    [mediaGroup setMediaTitle:title];
    
    [mediaGroup setMediaDescription:description];
    
    [mediaGroup setMediaCategories:categoryArray];
    
    [mediaGroup setMediaKeywords:keywords];
    
    
    //公開...NO 非公開...YES 限定公開...NOにして
    /*
    [entry addAccessControl:[GDataYouTubeAccessControl
                             accessControlWithAction:@"list" permission:@"denied"]];
    を追加する
     */
    BOOL isPrivate = NO;
    if (self.publishKind == YouTubePublishKindPublic
        || self.publishKind == YouTubePublishKindUnlisted) {
        isPrivate = NO;
    } else {
        isPrivate = YES;
    }
    [mediaGroup setIsPrivate:isPrivate];
    
    NSString *mimeType = [GDataUtilities MIMETypeForFileAtPath:self.videoFilePath
                                               defaultMIMEType:@"video/mov"];
    
    
    GDataEntryYouTubeUpload *entry;
    
    entry = [GDataEntryYouTubeUpload uploadEntryWithMediaGroup:mediaGroup
             
                                                          data:self.videoData
             
                                                      MIMEType:mimeType
             
                                                          slug:fileName];
    
    if (self.publishKind == YouTubePublishKindUnlisted) {
        [entry addAccessControl:[GDataYouTubeAccessControl
                                 accessControlWithAction:@"list" permission:@"denied"]];
    }
    
    SEL progressSel = @selector(ticket:hasDeliveredByteCount:ofTotalByteCount:);
    [self.youtubeService setServiceUploadProgressSelector:progressSel];
    
    
    GDataServiceTicket *ticket = nil;
    
    ticket = [self.youtubeService fetchEntryByInsertingEntry:entry
              
                                                  forFeedURL:url
              
                                                    delegate:self
              
                                           didFinishSelector:@selector(uploadTicket:finishedWithEntry:error:)];
    
    
    
    [self setUploadTicket:ticket];
    
    
    //    GTMHTTPUploadFetcher *uploadFetcher = (GTMHTTPUploadFetcher *)[ticket objectFetcher];
    //
    //    [uploadFetcher setLocationChangeBlock:^(NSURL *url) {
    //        
    //        [self setUploadLocationURL:url];
    //    
    //    }];

}

- (IBAction)cancel:(id)sender {
    if ([self.delegate respondsToSelector:@selector(YouTubeUploaderDidFinish)]) {
        [self.delegate YouTubeUploaderDidFinish];
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    [self dismissViewControllerAnimated:YES completion:nil];
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
    [self dismissModalViewControllerAnimated:YES];
#endif
}

- (GDataServiceGoogleYouTube *)makeYoutubeServiceWithAuth:(GTMOAuth2Authentication *)auth {
    
    if (!self.youtubeService) {
        self.youtubeService = [[GDataServiceGoogleYouTube alloc] init];
        
        [self.youtubeService setShouldCacheResponseData:YES];
        [self.youtubeService setServiceShouldFollowNextLinks:YES];
        [self.youtubeService setIsServiceRetryEnabled:YES];
    }
    [self.youtubeService setYouTubeDeveloperKey:YouTubeDeveloperKey];
    [self.youtubeService setAuthorizer:auth];
    return self.youtubeService;
}

- (void)setUploadTicket:(GDataServiceTicket *)ticket {
    [_mUploadTicket release];
    self.mUploadTicket = [ticket retain];
}

- (void)setUploadLocationURL:(NSURL *)url {
    [_mUploadLocationURL release];
    self.mUploadLocationURL = [url retain];
}

- (void)uploadTicket:(GDataServiceTicket *)ticket finishedWithEntry:(GDataEntryYouTubeVideo *)videoEntry error:(NSError *)error

{
    
    [SVProgressHUD dismiss];
    
    NSLog(@"upload callbackkkk");
    
    NSLog(@"userData : %@", videoEntry.userData);
    
    
    
    if (error == nil) {
        
        NSString *mes = [NSString stringWithFormat:@"%@ %@", [[videoEntry title] stringValue], NSLocalizedString(@"was uploeded to YouTube", @"was uploeded to YouTube")];

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Upload success", @"Upload success")
                              
                                                        message:mes
                              
                                                       delegate:nil
                              
                                              cancelButtonTitle:@"OK"
                              
                                              otherButtonTitles:nil];
        
        [alert show];
        [alert release];
        
    } else {
        NSString *mes = [NSString stringWithFormat:@"%@:%@", NSLocalizedString(@"error", @"error"), [error description]];

        LOG(@"エラー\n\n%@\n\n", [error description]);
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error", @"error")
                              
                                                        message:mes
                              
                                                       delegate:nil
                              
                                              cancelButtonTitle:@"OK"
                              
                                              otherButtonTitles:nil];
        
        [alert show];
        [alert release];
        
    }
    cancelButton.enabled = uploadButton.enabled = YES;
    [self setUploadTicket:nil];
    
}

- (void)ticket:(GDataServiceTicket *)ticket hasDeliveredByteCount:(unsigned long long)numberOfBytesRead ofTotalByteCount:(unsigned long long)dataLength
{
    float progress = (float)numberOfBytesRead/dataLength;
    NSLog(@"numberOfBytesRead/dataLength => %llu/%llu = %f",numberOfBytesRead, dataLength, progress);
    [SVProgressHUD showProgress:progress status:NSLocalizedString(@"Uploading Video", @"Uploading Video")];
}

#pragma mark - Fetch the YouTube Categories
- (NSString *)youtubeCategoryNameWithIndex:(NSInteger)index {
    if (self.youtubeCategoryList != nil && [self.youtubeCategoryList count] > 0) {
        NSDictionary *dic = [self.youtubeCategoryList objectAtIndex:index];
        NSArray *objects = [dic allValues];
        
        NSString *category = [objects objectAtIndex:0];
        
        return category;
    } else {
        return @"";
    }
}

- (NSString *)youtubeCategoryTermWithIndex:(NSInteger)index {
    if (self.youtubeCategoryList != nil && [self.youtubeCategoryList count] > 0) {
        NSDictionary *dic = [self.youtubeCategoryList objectAtIndex:index];
        NSArray *keys = [dic allKeys];
        
        NSString *term = [keys objectAtIndex:0];
        return term;
    } else {
        return @"";
    }
}

- (void)fetchStandardCategories {
    
    // This method initiates a fetch and parse of the assignable categories.
    // If successful, the callback loads the category pop-up with the
    // categories.
    
//    [SVProgressHUD showWithStatus:kMessageLoadingYouTubeCategory];
    
    NSURL *categoriesURL = [NSURL URLWithString:kGDataSchemeYouTubeCategory];
    GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithURL:categoriesURL];
    [fetcher setComment:@"YouTube categories"];
    [fetcher beginFetchWithDelegate:self
                  didFinishSelector:@selector(categoryFetcher:finishedWithData:error:)];
}


- (void)categoryFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error {
    [SVProgressHUD dismiss];
    
    if (error) {
        NSLog(@"categoryFetcher:%@ failedWithError:%@", fetcher, error);
        return;
    }
    
    // The categories document looks like
    //  <app:categories>
    //    <atom:category term='Film' label='Film &amp; Animation'>
    //      <yt:browsable />
    //      <yt:assignable />
    //    </atom:category>
    //  </app:categories>
    //
    // We only want the categories which are assignable. We'll use XPath to
    // select those, then get the string value of the resulting term attribute
    // nodes.
    
    NSString *const path = @"app:categories/atom:category[yt:assignable]";
    
    NSXMLDocument *xmlDoc = [[[NSXMLDocument alloc] initWithData:data
                                                         options:0
                                                           error:&error] autorelease];
    if (xmlDoc == nil) {
        NSLog(@"category fetch could not parse XML: %@", error);
    } else {
        NSArray *nodes = [xmlDoc nodesForXPath:path
                                         error:&error];
        
        unsigned int numberOfNodes = [nodes count];
        if (numberOfNodes == 0) {
            NSLog(@"category fetch could not find nodes: %@", error);
        } else {
            for (int idx = 0; idx < numberOfNodes; idx++) {
                NSXMLElement *category = [nodes objectAtIndex:idx];
                
                NSString *term = [[category attributeForName:@"term"] stringValue];
                NSString *label = [[category attributeForName:@"label"] stringValue];
                
                if (label == nil) label = term;
                NSDictionary *dic = [NSDictionary dictionaryWithObject:label forKey:term];
                [self.youtubeCategoryList addObject:dic];
            }
        }
    }
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rowCount = 0;
    switch (section) {
        //タイトルと説明
        case 0:
            rowCount = 2;
            break;
        //タグ
        case 1:
            rowCount = 1;
            break;
        //カテゴリ
        case 2:
            rowCount = 1;
            break;
        //公開設定
        case 3:
            rowCount = 3;
            break;
        //アカウント表示
        case 4:
            rowCount = 1;
            break;
        default:
            break;
    }
    return rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"CellIdentifier";
    static NSString *checkMarkCellIdentifier = @"CheckMarkCell";
    
    switch (indexPath.section) {
        //タイトルと説明
        case 0:
        {
            if (indexPath.row == 0) {
                if (self.titleCell == nil) {
                    NSArray *tmpArray = [[NSBundle mainBundle] loadNibNamed:@"SingleLineTextCell" owner:self options:nil];
                    self.titleCell = [tmpArray objectAtIndex:0];
                    [self.titleCell setPlaceHolderText:NSLocalizedString(@"Title", @"Title")];
                }
                return self.titleCell;
            } else if (indexPath.row == 1) {
                if (self.descriptionCell == nil) {
                    NSArray *tmpArray = [[NSBundle mainBundle] loadNibNamed:@"DescriptionCell" owner:self options:nil];
                    self.descriptionCell = [tmpArray objectAtIndex:0];
                    [self.descriptionCell setPlaceHolderText:NSLocalizedString(@"Description", @"Description")];
                }
                return self.descriptionCell;
            }
        }
            break;
        //タグ
        case 1:
        {
            if (indexPath.row == 0) {
                if (self.tagsCell == nil) {
                    NSArray *tmpArray = [[NSBundle mainBundle] loadNibNamed:@"SingleLineTextCell" owner:self options:nil];
                    self.tagsCell = [tmpArray objectAtIndex:0];
                    [self.tagsCell setPlaceHolderText:NSLocalizedString(@"Tags", @"Tags")];
                }
                return self.tagsCell;
            }
        }
            break;
        //カテゴリ
        case 2:
        {
            if (indexPath.row == 0) {
                if (self.categoryCell == nil) {
                    self.categoryCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier] autorelease];
                    
                }
                self.categoryCell.textLabel.text = NSLocalizedString(@"Category", @"Category");
                self.categoryCell.detailTextLabel.text = [self youtubeCategoryNameWithIndex:self.selectedCategoryIndex];
                return self.categoryCell;
            }
        }
            break;
        //公開設定
        case 3:
        {
            if (indexPath.row == 0) {
                if (self.publicCell == nil) {
                    self.publicCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:checkMarkCellIdentifier] autorelease];
                }
                self.publicCell.textLabel.text = NSLocalizedString(@"Public", @"PublishKindPublicTitle");
                self.publicCell.detailTextLabel.text = NSLocalizedString(@"Anyone can search for and view", @"PublishKindPublicDescription");
                
                if (self.publishKind == YouTubePublishKindPublic) {
                    self.publicCell.accessoryType = UITableViewCellAccessoryCheckmark;
                } else {
                    self.publicCell.accessoryType = UITableViewCellAccessoryNone;
                }
                return self.publicCell;
            } else if (indexPath.row == 1) {
                if (self.unlistedCell == nil) {
                    self.unlistedCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:checkMarkCellIdentifier] autorelease];
                }
                
                if (self.publishKind == YouTubePublishKindUnlisted) {
                    self.unlistedCell.accessoryType = UITableViewCellAccessoryCheckmark;
                } else {
                    self.unlistedCell.accessoryType = UITableViewCellAccessoryNone;
                }
                self.unlistedCell.textLabel.text = NSLocalizedString(@"Unlisted", @"PublishKindUnlistedTitle");
                self.unlistedCell.detailTextLabel.text = NSLocalizedString(@"Anyone with a link can view", @"PublishKindUnlistedDescription");
                return self.unlistedCell;
            } else if (indexPath.row == 2) {
                if (self.privateCell == nil) {
                    self.privateCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:checkMarkCellIdentifier] autorelease];
                }
                if (self.publishKind == YouTubePublishKindPrivate) {
                    self.privateCell.accessoryType = UITableViewCellAccessoryCheckmark;
                } else {
                    self.privateCell.accessoryType = UITableViewCellAccessoryNone;
                }
                self.privateCell.textLabel.text = NSLocalizedString(@"Private", @"PublishKindPrivateTitle");
                self.privateCell.detailTextLabel.text = NSLocalizedString(@"Only specific YouTube users can view", @"PublishKindPrivateDescription");
                return self.privateCell;
            }
        }
            break;
        //アカウント表示
        case 4:
        {
            if (indexPath.row == 0) {
                if (self.accountCell == nil) {
                    self.accountCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier] autorelease];
                    self.accountCell.textLabel.text = NSLocalizedString(@"Account:", @"Account:");
                    GoogleManager *googleManager = (GoogleManager *)[GoogleManager sharedManager];
                    if (googleManager.googleMailAddress == nil) {
                        self.accountCell.detailTextLabel.text = self.googleMailAddress;
                    } else {
                        self.accountCell.detailTextLabel.text = [googleManager getGoogleMailAddress];
                    }
                }
                return self.accountCell;
            }
        }
            break;
        default:
            break;
    }
	return nil;
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return NSLocalizedString(@"Enter the tags separated by commas.", @"Enter the tags separated by commas.");
    }
    return @"";
}

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[theTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        //タイトルと説明
        case 0:
            break;
        //タグ
        case 1:
            break;
        //カテゴリ
        case 2:
        {

            [self.titleCell.textField resignFirstResponder];
            [self.descriptionCell.textView resignFirstResponder];
            [self.tagsCell.textField resignFirstResponder];

            if (!self.isShowingPicker) {
                self.pickerBaseView.frame = CGRectMake(0, [UIScreen getScreenHeight] + 260, 320, 260);
                [[[UIApplication sharedApplication] keyWindow] addSubview:self.pickerBaseView];
                [UIView animateWithDuration:0.3f
                                 animations:^{
                                     self.pickerBaseView.frame = CGRectMake(0, [UIScreen getScreenHeight] - 260, 320, 260);
                                 }];
                self.isShowingPicker = YES;
            }
        }
            break;
        //公開設定
        case 3:
        {
            
            if (indexPath.row == 0) {
                self.publicCell.accessoryType = UITableViewCellAccessoryCheckmark;
                self.unlistedCell.accessoryType = UITableViewCellAccessoryNone;
                self.privateCell.accessoryType = UITableViewCellAccessoryNone;
                
                self.publishKind = YouTubePublishKindPublic;
            } else if (indexPath.row == 1) {
                self.unlistedCell.accessoryType = UITableViewCellAccessoryCheckmark;
                self.publicCell.accessoryType = UITableViewCellAccessoryNone;
                self.privateCell.accessoryType = UITableViewCellAccessoryNone;
                
                self.publishKind = YouTubePublishKindUnlisted;
            } else {
                self.privateCell.accessoryType = UITableViewCellAccessoryCheckmark;
                self.publicCell.accessoryType = UITableViewCellAccessoryNone;
                self.unlistedCell.accessoryType = UITableViewCellAccessoryNone;
                
                self.publishKind = YouTubePublishKindPrivate;
            }
        }
            break;
        //アカウント表示
        case 4:
        {
            NSString *mes = [NSString stringWithFormat:@"%@\n%@", NSLocalizedString(@"Account:", @"Account:"), self.googleMailAddress];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"YouTube"
                                                             message:mes
                                                            delegate:self
                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                                   otherButtonTitles:NSLocalizedString(@"Sign Out", @"Sign Out"), nil];
            
            [alert show];
            [alert release];
        }
            break;
        default:
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 0;
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            height = 44.0f;
        } else {
            height = 100.0f;
        }
    } else {
        height = 44.0f;
    }
    return height;
}

#pragma mark - UIPickerView DataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return [self.youtubeCategoryList count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    return [self youtubeCategoryNameWithIndex:row];
}

- (IBAction)closePicker:(id)sender {
    self.selectedCategoryIndex = [self.categoryPicker selectedRowInComponent:0];
    [UIView animateWithDuration:0.3f
                     animations:^{
                         self.pickerBaseView.frame = CGRectMake(0, [UIScreen getScreenHeight] + 260, 320, 260);
                     } completion:^(BOOL finished) {
                         [self.pickerBaseView removeFromSuperview];
                         self.isShowingPicker = NO;

                     }];
}

#pragma mark - UIPickerView Delegate
- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    self.selectedCategoryIndex = row;
    self.categoryCell.detailTextLabel.text = [self youtubeCategoryNameWithIndex:row];
}

#pragma mark - UIAlertView Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    GoogleManager *manager = (GoogleManager *)[GoogleManager sharedManager];
    if (buttonIndex == 1) {
        [manager signOut];
        if ([self.delegate respondsToSelector:@selector(YouTubeUploaderDidFinish)]) {
            [self.delegate YouTubeUploaderDidFinish];
        }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
        [self dismissViewControllerAnimated:YES completion:nil];
#else
        [self dismissModalViewControllerAnimated:YES];
#endif
    }
}

@end
