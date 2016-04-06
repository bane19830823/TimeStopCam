//
//  HostVideoDaraReceiveCell.m
//  TimeSliceCam
//
//  Created by Bane on 12/12/29.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "HostVideoDataReceiveCell.h"

@implementation HostVideoDataReceiveCell

@synthesize peerNameLabel;
@synthesize signalView;

- (void)dealloc {
    self.peerNameLabel = nil;
    self.signalView = nil;
    
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

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
