
#import "HostViewController.h"
#import "ClientViewController.h"
#import "AVCamViewController.h"
#import "HostVideoDataReceiveViewController.h"
#import "AVPlayerViewController.h"
#import "NADView.h"

@interface MainViewController : UIViewController
<HostViewControllerDelegate, ClientViewControllerDelegate,
AVCamViewControllerDelegate, HostVideoDataReceiveViewControllerDelegate,
AVPlayerViewControllerDelagate, NADViewDelegate>

- (IBAction)showImagePicker:(UIButton *)sender;
- (void)dataTransferFinished;

@end
