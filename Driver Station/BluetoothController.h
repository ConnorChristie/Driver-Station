//
//  BluetoothController.h
//  Driver Station
//
//  Created by Connor Christie on 9/24/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import <Foundation/Foundation.h>

@interface BluetoothController : NSObject <MCSessionDelegate>

@property (nonatomic, strong) MCPeerID *peerID;
@property (nonatomic, strong) MCSession *session;

@property (nonatomic, strong) MCBrowserViewController *browser;
@property (nonatomic, strong) MCAdvertiserAssistant *advertiser;

-(void) sendMessage:(NSString *) message;
-(void) setConnected:(BOOL) connected;

@end
