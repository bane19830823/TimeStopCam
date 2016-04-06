//
//  ClientViewController.h
//  TimeSliceCam
//
//  Created by Bane on 12/09/29.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimeSliceCamClient.h"
#import "NADView.h"

@class ClientViewController;

@protocol ClientViewControllerDelegate <NSObject>

- (void)clientViewControllerDidCancel:(ClientViewController *)controller;
- (void)clientViewController:(ClientViewController *)controller didDisconnectWithReason:(QuitReason)reason;
- (void)clientViewController:(ClientViewController *)controller
 startCapturingWithGKSession:(GKSession *)session
                    peerName:(NSString *)name
                      server:(NSString *)peerID;

@end

@interface ClientViewController : UIViewController
<TimeSliceCamClientDelegate,UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, NADViewDelegate>


@property (nonatomic, retain) IBOutlet UILabel *headingLabel;
@property (nonatomic, retain) IBOutlet UILabel *nameLabel;
@property (nonatomic, retain) IBOutlet UITextField *nameTextField;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, assign) id <ClientViewControllerDelegate> delegate;

@property (nonatomic, retain) IBOutlet UIView *waitView;
@property (nonatomic, retain) IBOutlet UILabel *waitLabel;

@end
