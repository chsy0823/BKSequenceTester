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
#import "BluetoothDevice.h"
#import "BluetoothManager.h"

#define OBSERVERNAME @"networkCallback"

#define PATHDEFAULT 1
#define PATHSPEAKER 2
#define PATHBLUETOOTH   3

@interface MainViewController () <PopupDelegate, MDBluetoothObserverProtocol>

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self readyForNetwork];
    packetArray = [NSMutableArray array];
    
    isBTConnected = false;
    isLoopBackOn = false;
    audioController = [[AudioController alloc] init];
    
    PacketObject *temp1 = [[PacketObject alloc]init];
    temp1.command = @"System is Ready";
    temp1.isSystemMsg = true;
    
    [packetArray addObject:temp1];
    
    NSString *path = [NSString stringWithFormat:@"%@/sound.wav", [[NSBundle mainBundle] resourcePath]];
    NSURL *soundUrl = [NSURL fileURLWithPath:path];
    
    // Create audio player object and initialize with URL to sound
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
    audioSession = [AVAudioSession sharedInstance];
    
    //currentVolume = [audioPlayer volume];
    currentVolume = [[MPMusicPlayerController applicationMusicPlayer] volume];
    
    [[MDBluetoothManager sharedInstance] registerObserver:self];
    
    deviceToConnect = @"CLUSTER TONG";
    
//    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
//    NSMutableArray* arr = [NSMutableArray array ];
//    
//    [arr addObject:[NSNumber numberWithBool:YES]];    //stop for 500ms
//    [arr addObject:[NSNumber numberWithInt:500]];
//    
//    [dict setObject:arr forKey:@"VibePattern"];
//    [dict setObject:[NSNumber numberWithInt:1] forKey:@"Intensity"];
//    
//    
//    AudioServicesPlaySystemSoundWithCompletion(4095,nil,dict);
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    [[MDBluetoothManager sharedInstance] turnBluetoothOn];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)readyForNetwork {
    
    NSNotificationCenter *sendNotification = [NSNotificationCenter defaultCenter];
    
    [sendNotification addObserver:self selector:@selector(networkCallback:) name:OBSERVERNAME object:nil];
    networkController = [NetworkController sharedInstance];
    networkController.currentObserverName = OBSERVERNAME;
    
}

- (void)networkCallback:(NSNotification*)notification {

    NSDictionary* dict = (NSDictionary*)notification.userInfo;
    NSLog(@"%@",dict);
    
    BOOL interruptFlag = [(NSNumber*)[dict objectForKey:@"interruptFlag"] boolValue];
    NSString *msg = [dict objectForKey:@"msg"];
    NSDictionary *dataDict = [dict objectForKey:@"data"];
    
    if(interruptFlag) {
        
        PacketObject *packetObj = [[PacketObject alloc]init];
        packetObj.isSystemMsg = true;
        packetObj.command = msg;
        [packetArray addObject:packetObj];
        [self.tableView reloadData];
        
        return;
    }
   
    NSString *fullDataRcv = [dataDict objectForKey:@"fullData"];
    NSInteger command = [(NSNumber*)[dataDict objectForKey:@"command"] integerValue];
    NSString *commandString = @"";
    NSString *data = [dataDict objectForKey:@"data"];
    int value;
    
    PacketObject *packetObj = [[PacketObject alloc]init];
    packetObj.RXTX = RX;
    packetObj.fullData = fullDataRcv;
    
    switch (command) {
        case REMOTE_CONNECTBT:
            
            commandString = @"Connect BT";
            if([data length]>0) {
                deviceToConnect = data;
            }
            
            [self connectBluetooth];
            break;
        case REMOTE_DISCONNECTBT:
            
            commandString = @"Disconnect BT";
            [self disconnectBluetooth];
            break;
        case REMOTE_EARWavePlay:
            
            commandString = @"EAR Wave play";
            value = [data intValue];
            
            if(isBTConnected) {
                commandString = @"Bluetooth is connected..";
            }
            else {
                if(value == 1)
                    [self playSound:PATHDEFAULT Stop:false];
            }
            break;
        case REMOTE_RCVWavePlay:
            commandString = @"RCV Wave play";
            value = [data intValue];
            
            if(isBTConnected) {
                commandString = @"Bluetooth is connected..";
            }
            else {
                if(value == 1)
                    [self playSound:PATHDEFAULT Stop:false];
            }
            break;
        case REMOTE_SPKWavePlay:
            commandString = @"SPK Wave play";
            value = [data intValue];
            
            if(isBTConnected) {
                commandString = @"Bluetooth is connected..";
            }
            else {
                if(value == 1)
                    [self playSound:PATHSPEAKER Stop:false];
            }
            
            break;
        case REMOTE_SETVOLUME:
            commandString = [NSString stringWithFormat:@"Set volume to %@",data];
            value = [data intValue];
            float volume = value/100;
            
            [self setVolume:volume];
            break;
        case REMOTE_LOOPBACKMODE:
            
            commandString = [NSString stringWithFormat:@"Set loopback mode to %@",data];
            value = [data intValue];
            
            if(value == 0) { //off
                if(isLoopBackOn) {
                    isLoopBackOn = false;
                    [self loopbackMode:isLoopBackOn];
                }
            }
            else { //on
                if(!isLoopBackOn) {
                    isLoopBackOn = true;
                    [self loopbackMode:isLoopBackOn];
                }
            }

            break;
        case REMOTE_VIBMOTOR:
            
            commandString = [NSString stringWithFormat:@"vibrate for %@ sec",data];
            value = [data intValue];
            [self playVibrate:value];
            break;
        case BTSPKWAV:

            commandString = @"BT SPK play";
            if(!isBTConnected ) {
                 commandString = @"Bluetooth is not connected..";
            }
            else {
                [self playSound:PATHBLUETOOTH Stop:false];
            }
            break;
        case SEND_MESSAGE:
            commandString = [NSString stringWithFormat:@"Receive message : %@",data];
            
            break;
        case SEND_BTINFO:
            commandString = [NSString stringWithFormat:@"Receive BT info : %@",data];
            break;
        case GETINFO:
            commandString = [NSString stringWithFormat:@"Get Device info"];
            break;
        default:
            break;
    }
    
    packetObj.command = commandString;
    
    [packetArray addObject:packetObj];
    
    [self.tableView reloadData];
    
}

- (void)showIPPopup {
    
    NSArray *cellArray = [[NSBundle mainBundle] loadNibNamed:@"PopupCollection" owner:self options:nil];
    
    PopupViewController *popup = [cellArray objectAtIndex:0];
    popup.delegate = self;
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    [self presentViewController:popup animated:NO completion:nil];
}

- (AVAudioSessionPortDescription*)bluetoothAudioDevice
{
    NSArray* bluetoothRoutes = @[AVAudioSessionPortBluetoothA2DP, AVAudioSessionPortBluetoothLE, AVAudioSessionPortBluetoothHFP];
    return [self audioDeviceFromTypes:bluetoothRoutes];
}


- (AVAudioSessionPortDescription*)audioDeviceFromTypes:(NSArray*)types
{
    NSArray* routes = [[AVAudioSession sharedInstance] availableInputs];
    for (AVAudioSessionPortDescription* route in routes)
    {
        if ([types containsObject:route.portType])
        {
            return route;
        }
    }
    return nil;
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
        else if(path == PATHSPEAKER) {
            [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
            [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
        }
        else {

            [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:nil];
            AVAudioSessionPortDescription* _bluetoothPort = [self bluetoothAudioDevice];
            [[AVAudioSession sharedInstance] setPreferredInput:_bluetoothPort error:nil];
        }
        
        [audioPlayer play];
    }
}

- (void)connectBluetooth {
    
    BOOL isPowered = [[MDBluetoothManager sharedInstance] bluetoothIsPowered];
    
    if(!isPowered) {
        [[MDBluetoothManager sharedInstance] turnBluetoothOn];
    }
    
    if(connectedDevice != nil) {
        [connectedDevice.bluetoothDevice connect];
    }
    else if(!isBTConnected) {
        
        [[MDBluetoothManager sharedInstance] startScan];
    }
}

- (void)disconnectBluetooth {
    
    if(isBTConnected) {
        [connectedDevice.bluetoothDevice disconnect];
        //[[MDBluetoothManager sharedInstance] turnBluetoothOff];
        [[MDBluetoothManager sharedInstance] endScan];
        isBTConnected = false;
        
        if([networkController isConnectedToServer]) {
            [networkController sendCommand:DISCONNECTOK Data:@""];
        }
    }
}

- (void)loopbackMode:(BOOL)on {
    
    if(on) {
        [audioController startIOUnit];
    }
    else {
        [audioController stopIOUnit];
    }
}

- (void)dealloc {
    
    [self disconnectBluetooth];
}
- (void)setVolume:(float)volume {
    
    if(volume > 1)
        volume = 1;
    else if(volume <0)
        volume = 0;
    
    currentVolume = volume;
    NSLog(@"volume = %f",currentVolume);
    [[MPMusicPlayerController applicationMusicPlayer]setVolume:currentVolume];
    //[audioPlayer setVolume:volume];
}

- (void)playVibrate:(int)sec {
    
//    int offset = (int)roundf(10/3*sec);
//    
//    for (int i = 1; i < offset; i++)
//    {
//        [self performSelector:@selector(vibe:) withObject:self afterDelay:i *.3f];
//    }
    
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    NSMutableArray* arr = [NSMutableArray array ];
    
    [arr addObject:[NSNumber numberWithBool:YES]]; //vibrate for 5000ms
    [arr addObject:[NSNumber numberWithInt:sec*1000]];
    
    [dict setObject:arr forKey:@"VibePattern"];
    [dict setObject:[NSNumber numberWithInt:1] forKey:@"Intensity"];
    
    // suppress warnings
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wall"
    AudioServicesStopSystemSound(kSystemSoundID_Vibrate);
    AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate,nil,dict);
#pragma clang diagnostic pop
    
}

-(void)vibe:(id)sender
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
}

- (IBAction)connectDirect:(id)sender {
    
    [self showIPPopup];
}
- (IBAction)showMenu:(id)sender {
    [self.menuContainerViewController setMenuState:MFSideMenuStateLeftMenuOpen];
}

- (void)executeSideMenuAction:(NSInteger)command {
    
    PacketObject *packetObj = [[PacketObject alloc]init];
    packetObj.isSystemMsg = true;
    NSString *commandString = @"";
    
    switch (command) {
        case ConnectTCPIP:
            [self showIPPopup];
            break;
        case DisconnectTCPIP:
            [networkController disconnect];
            break;
        case ConnectBT:
            commandString = @"connect bt";
            [self connectBluetooth];
            break;
        case DisconnectBT:
            commandString = @"disconnect bt";
            [self disconnectBluetooth];
            break;
        case SPKWavePlay:
            commandString = @"SPK wav play from menu";
            if(!isBTConnected)
                [self playSound:PATHSPEAKER Stop:false];
            else {
                commandString = @"Bluetooth is connected..";
            }
            break;
        case RCVWavePlay:
            commandString = @"RCV wav play from menu";
            if(!isBTConnected) {
                [self playSound:PATHDEFAULT Stop:false];
            }
            else {
                commandString = @"Bluetooth is connected..";
            }
            break;
        case EARWavePlay:
            commandString = @"EAR wav play from menu";
            if(!isBTConnected) {
                [self playSound:PATHDEFAULT Stop:false];
            }
            else {
                commandString = @"Bluetooth is connected..";
            }
            break;
        case LoopBackONOFF:
            
            if(isLoopBackOn) {
                commandString = @"loopback off from menu";
                isLoopBackOn = false;
            }
            else {
                commandString = @"loopback on from menu";
                isLoopBackOn = true;
            }
            
            [self loopbackMode:isLoopBackOn];
            break;
        case VIBRATE:
            commandString = @"Vibrate from menu(default 3 sec)";
            [self playVibrate:3];
            break;
            
        case VolumeUP:
            commandString = @"Volume up from menu";
            currentVolume += 0.0625;
            [self setVolume:currentVolume];
            break;
        case VolumeDOWN:
            commandString = @"Volume down from menu";
            currentVolume -= 0.0625;
            [self setVolume:currentVolume];
            break;
            
        case BTSPKPLAY:
            commandString = @"BT spk play from menu";
            if(isBTConnected ) {
                [self playSound:PATHBLUETOOTH Stop:false];
            }
            else {
                 commandString = @"Bluetooth is not connected..";
            }
            break;
        default:
            
            break;
    }
    
    packetObj.command = commandString;
    [packetArray addObject:packetObj];
    [self.tableView reloadData];
}


- (void)receivedBluetoothNotification:(MDBluetoothNotification)bluetoothNotification {
    
    NSArray* detectedBluetoothDevices = [[MDBluetoothManager sharedInstance] discoveredBluetoothDevices];
    BluetoothManager *btManager = [BluetoothManager sharedInstance];
    PacketObject *packetObj = [[PacketObject alloc]init];
    
    switch (bluetoothNotification) {
        case MDBluetoothAvailabilityChangedNotification:
            
            break;
        case MDBluetoothPowerChangedNotification:
            
            break;
        case MDBluetoothDeviceDiscoveredNotification:
            
            if(!isBTConnected) {
                if([detectedBluetoothDevices count] > 0) {
                    
                    for(MDBluetoothDevice* bluetoothDevice in detectedBluetoothDevices) {
                        
                        NSLog(@"device name = %@",bluetoothDevice.name);
                        if([bluetoothDevice.name isEqualToString:deviceToConnect]) {
                            [btManager setDevicePairingEnabled:true];
                            [btManager setConnectable:true];
                            [btManager setPincode:@"0000" forDevice:bluetoothDevice.bluetoothDevice];
                            [btManager connectDevice:bluetoothDevice.bluetoothDevice];
                            //[btManager connectDevice:bluetoothDevice.bluetoothDevice withServices:0x00002000];
                            connectedDevice = bluetoothDevice;
                        }
                    }
                }
            }
            
            break;
        case MDBluetoothDeviceRemovedNotification:
            
            break;
        case MDBluetoothDeviceConnectSuccessNotification:
            
            if(!isBTConnected) {
                isBTConnected = true;
                packetObj.isSystemMsg = true;
                packetObj.command = [NSString stringWithFormat:@"(%@) is connected",connectedDevice.name];
                [packetArray addObject:packetObj];
                [self.tableView reloadData];
                
                if([networkController isConnectedToServer]) {
                    [networkController sendCommand:CONNECTOK Data:@""];
                }
            }
            
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
    if(object.isSystemMsg) {
        cell = [topLevelObjects objectAtIndex:2];
    }
    else
        cell = [topLevelObjects objectAtIndex:object.RXTX-1];

    cell.contentLabel.text = [NSString stringWithFormat:@"    %@",object.command];
    
    return cell;
}

#pragma mark PopupDelegate

- (void)setIP:(NSString*)ip Port:(NSString*)port {
    
    [networkController setServerWithIP:ip Port:[port intValue]];
    //[networkController sendCommand:002 Data:@"test"];
}


@end
