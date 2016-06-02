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
    
    mgr = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    NSDictionary *scanOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    [mgr scanForPeripheralsWithServices:nil options:scanOptions];
    //manager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
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
            break;
        case REMOTE_DISCONNECTBT:
            commandString = @"Disconnect BT";
            break;
        case REMOTE_EARWavePlay:
            commandString = @"EAR Wave play";
            value = [data intValue];
            if(!isBTConnected && value == 1)
                [self playSound:PATHDEFAULT Stop:false];
            break;
        case REMOTE_RCVWavePlay:
            commandString = @"RCV Wave play";
            value = [data intValue];
            if(!isBTConnected && value == 1)
                [self playSound:PATHDEFAULT Stop:false];
            break;
        case REMOTE_SPKWavePlay:
            commandString = @"SPK Wave play";
            value = [data intValue];
            if(!isBTConnected && value == 1)
                [self playSound:PATHSPEAKER Stop:false];
            
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
            if(isBTConnected ) {
                
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
        [audioController startIOUnit];
    }
    else {
        [audioController stopIOUnit];
    }
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
    
    int offset = (int)roundf(10/3*sec);
    
    for (int i = 1; i < offset; i++)
    {
        [self performSelector:@selector(vibe:) withObject:self afterDelay:i *.3f];
    }
}

-(void)vibe:(id)sender
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
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
            [self connectBluetooth];
            break;
        case DisconnectBT:
            [self disconnectBluetooth];
            break;
        case SPKWavePlay:
            commandString = @"SPK wav play from menu";
            if(!isBTConnected)
                [self playSound:PATHSPEAKER Stop:false];
            break;
        case RCVWavePlay:
            commandString = @"RCV wav play from menu";
            if(!isBTConnected)
                [self playSound:PATHDEFAULT Stop:false];
            break;
        case EARWavePlay:
            commandString = @"EAR wav play from menu";
            if(!isBTConnected)
                [self playSound:PATHDEFAULT Stop:false];
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
        default:
            
            break;
    }
    
    packetObj.command = commandString;
    [packetArray addObject:packetObj];
    [self.tableView reloadData];
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

#pragma mark Bluetooth delegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    NSString *messtoshow;
    
    switch (central.state) {
        case CBCentralManagerStateUnknown:
        {
            messtoshow=[NSString stringWithFormat:@"State unknown, update imminent."];
            break;
        }
        case CBCentralManagerStateResetting:
        {
            messtoshow=[NSString stringWithFormat:@"The connection with the system service was momentarily lost, update imminent."];
            break;
        }
        case CBCentralManagerStateUnsupported:
        {
            messtoshow=[NSString stringWithFormat:@"The platform doesn't support Bluetooth Low Energy"];
            break;
        }
        case CBCentralManagerStateUnauthorized:
        {
            messtoshow=[NSString stringWithFormat:@"The app is not authorized to use Bluetooth Low Energy"];
            break;
        }
        case CBCentralManagerStatePoweredOff:
        {
            messtoshow=[NSString stringWithFormat:@"Bluetooth is currently powered off."];
            NSLog(@"%@",messtoshow);
            break;
        }
        case CBCentralManagerStatePoweredOn:
        {
            
            messtoshow=[NSString stringWithFormat:@"Bluetooth is currently powered on and available to use."];
            
            [mgr scanForPeripheralsWithServices:nil options:@{ CBCentralManagerScanOptionAllowDuplicatesKey :@YES}];
            
            NSLog(@"%@",messtoshow);
            break;
            
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    
    NSLog(@"%@",[NSString stringWithFormat:@"%@",[advertisementData description]]);
    
    NSLog(@"%@",[NSString stringWithFormat:@"Discover:%@,RSSI:%@\n",[advertisementData objectForKey:@"kCBAdvDataLocalName"],RSSI]);
    NSLog(@"Discovered %@", peripheral.name);
    [mgr  connectPeripheral:peripheral options:nil];
}


- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    int state = peripheral.state;
    NSLog(@"Peripheral manager state =  %d", state);
    
    //Set the UUIDs for service and characteristic
    CBUUID *heartRateServiceUUID = [CBUUID UUIDWithString: @"180D"];
    CBUUID *heartRateCharacteristicUUID = [CBUUID UUIDWithString:@"2A37"];
    CBUUID *heartRateSensorLocationCharacteristicUUID = [CBUUID UUIDWithString:@"0x2A38"];
    
    
    //char heartRateData[2]; heartRateData[0] = 0; heartRateData[1] = 60;
    
    //Create the characteristics
    CBMutableCharacteristic *heartRateCharacteristic =
    [[CBMutableCharacteristic alloc] initWithType:heartRateCharacteristicUUID
                                       properties: CBCharacteristicPropertyNotify
                                            value:nil
                                      permissions:CBAttributePermissionsReadable];
    
    CBMutableCharacteristic *heartRateSensorLocationCharacteristic =
    [[CBMutableCharacteristic alloc] initWithType:heartRateSensorLocationCharacteristicUUID
                                       properties:CBCharacteristicPropertyRead
                                            value:nil
                                      permissions:CBAttributePermissionsReadable];
    //Create the service
    CBMutableService *myService = [[CBMutableService alloc] initWithType:heartRateServiceUUID primary:YES];
    myService.characteristics = @[heartRateCharacteristic, heartRateSensorLocationCharacteristic];
    
    //Publish the service
    NSLog(@"Attempting to publish service...");
    [peripheral addService:myService];
    
    //Set the data
    NSDictionary *data = @{CBAdvertisementDataLocalNameKey:@"iDeviceName",
                           CBAdvertisementDataServiceUUIDsKey:@[[CBUUID UUIDWithString:@"180D"]]};
    
    //Advertise the service
    NSLog(@"Attempting to advertise service...");
    [peripheral startAdvertising:data];
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error {
    
    if (error) {
        NSLog(@"Error publishing service: %@", [error localizedDescription]);
    }
    else NSLog(@"Service successfully published");
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral
                                       error:(NSError *)error {
    
    if (error) {
        NSLog(@"Error advertising: %@", [error localizedDescription]);
    }
    else NSLog(@"Service successfully advertising");
}


@end
