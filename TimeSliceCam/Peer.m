//
//  Peer.m
//  TimeSliceCam
//
//  Created by Bane on 12/10/16.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "Peer.h"

@implementation Peer

@synthesize peerNumber = _peerNumber;
@synthesize name = _name;
@synthesize peerID = _peerID;   //識別子

- (void)dealloc {
    LOG_METHOD;
#ifdef DEBUG
    LOG(@"dealloc %@", self);
#endif
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ peerID = %@, name = %@, peerNumber = %d", [super description], self.peerID, self.name, self.peerNumber];
}

@end
