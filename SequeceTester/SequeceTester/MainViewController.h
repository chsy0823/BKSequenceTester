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

@interface MainViewController : UIViewController<UITableViewDataSource, UITableViewDelegate> {
    
    NSMutableArray *packetArray;
    NetworkController *networkController;
    AVAudioPlayer *audioPlayer;
    AVAudioSession *audioSession;
    BOOL isBTConnected;

}

@property (nonatomic, weak) IBOutlet UITableView *tableView;

- (IBAction)showMenu:(id)sender;
- (void)executeSideMenuAction:(NSInteger)command;
@end

