//
//  ViewController.h
//  SequeceTester
//
//  Created by SuhyongChoi on 2016. 5. 21..
//  Copyright © 2016년 bako. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "MFSideMenu.h"
#import "NetworkController.h"
#import "AudioController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "MDBluetoothManager.h"

@interface MainViewController : UIViewController<UITableViewDataSource, UITableViewDelegate,UITableViewDataSource,UITableViewDelegate> {
    
    NSMutableArray *packetArray;
    NetworkController *networkController;
    AVAudioPlayer *audioPlayer;
    AVAudioSession *audioSession;
    BOOL isBTConnected;
    BOOL isLoopBackOn;
    AudioController *audioController;
    float currentVolume;
    MDBluetoothDevice *connectedDevice;

}

@property (nonatomic, weak) IBOutlet UITableView *tableView;
- (void)receivedBluetoothNotification:(MDBluetoothNotification)bluetoothNotification;

- (IBAction)showMenu:(id)sender;
- (void)executeSideMenuAction:(NSInteger)command;
@end

