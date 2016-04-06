//
//  HostViewController.h
//  TimeSliceCam
//
//  Created by Bane on 12/09/29.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimeSliceCamServer.h"
#import "CameraSession.h"
#import "NADView.h"

@class HostViewController;

@protocol HostViewControllerDelegate <NSObject>

- (void)hostViewControllerDidCancel:(HostViewController *)controller;
- (void)hostViewController:(HostViewController *)controller didEndSessionWithReason:(QuitReason)reason;
- (void)hostViewController:(HostViewController *)controller
  startShootingWithSession:(GKSession *)session
                peerName:(NSString *)name
                   clients:(NSArray *)clients;

@optional
- (void)hostViewController:(HostViewController *)controller
startVideoDataTransferWithSesion:(GKSession *)gkSession
                  shooters:(NSMutableArray *)shooters
                  peerName:(NSString *)serverName;

@end

@interface HostViewController : UIViewController
<TimeSliceCamServerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, CameraSessionDelegate, NADViewDelegate>


@property (nonatomic, retain) IBOutlet UILabel *headingLabel;
@property (nonatomic, retain) IBOutlet UILabel *nameLabel;
@property (nonatomic, retain) IBOutlet UITextField *nameTextField;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIButton *sequencialButton;
@property (nonatomic, retain) IBOutlet UIButton *simultaneousButton;
@property (nonatomic, assign) id <HostViewControllerDelegate> delegate;
@property (nonatomic, retain) CameraSession *cameraSession;
@property (nonatomic, retain) NSMutableArray *readyForShootingStateClients;


- (IBAction)startAction:(id)sender;
- (IBAction)sendShootingOrder:(id)sender;
- (IBAction)exitAction:(id)sender;

@end
