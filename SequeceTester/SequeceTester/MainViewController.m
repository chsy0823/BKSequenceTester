//
//  ViewController.m
//  SequeceTester
//
//  Created by SuhyongChoi on 2016. 5. 21..
//  Copyright © 2016년 bako. All rights reserved.
//

#import "MainViewController.h"
#import "ConsoleTableViewCell.h"
#import "PacketObject.h"
#import "PopupViewController.h"

#define OBSERVERNAME @"networkCallback"

#define PATHDEFAULT 1
#define PATHSPEAKER 2

@interface MainViewController () <PopupDelegate>

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self readyForNetwork];
    packetArray = [NSMutableArray array];
    
    isBTConnected = false;
    
    PacketObject *temp1 = [[PacketObject alloc]init];
    temp1.contents = @"Start Test";
    temp1.RXTX = RX;
    
    PacketObject *temp2 = [[PacketObject alloc]init];
    temp2.contents = @"Search Bluetooth";
    temp2.RXTX = TX;
    
    [packetArray addObject:temp1];
    [packetArray addObject:temp2];
    
    NSString *path = [NSString stringWithFormat:@"%@/sound.wav", [[NSBundle mainBundle] resourcePath]];
    NSURL *soundUrl = [NSURL fileURLWithPath:path];
    
    // Create audio player object and initialize with URL to sound
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
    audioSession = [AVAudioSession sharedInstance];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)readyForNetwork {
    
    NSNotificationCenter *sendNotification = [NSNotificationCenter defaultCenter];
    
    [sendNotification addObserver:self selector:@selector(networkCallback:) name:OBSERVERNAME object:nil];
    networkController = [NetworkController sharedInstance];
}

- (void)networkCallback:(NSNotification*)notification {

    NSDictionary* dict = (NSDictionary*)notification.userInfo;
    NSLog(@"%@",dict);
}

- (void)showIPPopup {
    
    NSArray *cellArray = [[NSBundle mainBundle] loadNibNamed:@"PopupCollection" owner:self options:nil];
    
    PopupViewController *popup = [cellArray objectAtIndex:0];
    popup.delegate = self;
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    [self presentViewController:popup animated:NO completion:nil];
}

- (void)playSound:(int)path Stop:(BOOL)stop {
    
    if(stop) {
        [audioPlayer stop];
    }
    else {
        
        if(path == PATHDEFAULT) {
            [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
            [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
        }
        else {
            [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
            [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
        }
        
        [audioPlayer play];
        
    }
}

- (void)connectBluetooth {
    
}

- (void)disconnectBluetooth {
    
}

- (void)loopbackMode:(BOOL)on {
    
    if(on) {
        
    }
    else {
        
    }
}


- (IBAction)showMenu:(id)sender {
    [self.menuContainerViewController setMenuState:MFSideMenuStateLeftMenuOpen];
}

- (void)executeSideMenuAction:(NSInteger)command {
    
    switch (command) {
        case ConnectTCPIP:
            [self showIPPopup];
            break;
        case DisconnectTCPIP:
            [networkController sendCommand:command];
            break;
        case ConnectBT:
            break;
        case DisconnectBT:
            break;
        case SPKWavePlay:
            if(!isBTConnected)
                [self playSound:PATHSPEAKER Stop:false];
            break;
        case RCVWavePlay:
            if(!isBTConnected)
                [self playSound:PATHDEFAULT Stop:false];
            break;
        case EARWavePlay:
            if(!isBTConnected)
                [self playSound:PATHDEFAULT Stop:false];
            break;
        default:
            
            break;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 22;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [packetArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   
    PacketObject *object = (PacketObject*)[packetArray objectAtIndex:indexPath.row];
    
    ConsoleTableViewCell *cell = nil;
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"MainCell" owner:self options:nil];
    cell = [topLevelObjects objectAtIndex:object.RXTX-1];

    cell.contentLabel.text = [NSString stringWithFormat:@"    %@",object.contents];
    
    return cell;
}

#pragma mark PopupDelegate

- (void)setIP:(NSString*)ip Port:(NSString*)port {
    
    NSLog(@"ip = %@ port = %@",ip,port);
}

@end
