//
//  ViewController.m
//  SequeceTester
//
//  Created by SuhyongChoi on 2016. 5. 21..
//  Copyright © 2016년 bako. All rights reserved.
//

#import "ViewController.h"
#import "ConsoleTableViewCell.h"
#import "PacketObject.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    packetArray = [NSMutableArray array];
    
    PacketObject *temp1 = [[PacketObject alloc]init];
    temp1.contents = @"Start Test";
    temp1.RXTX = RX;
    
    PacketObject *temp2 = [[PacketObject alloc]init];
    temp2.contents = @"Search Bluetooth";
    temp2.RXTX = TX;
    
    [packetArray addObject:temp1];
    [packetArray addObject:temp2];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showMenu:(id)sender {
    [self.menuContainerViewController setMenuState:MFSideMenuStateLeftMenuOpen];
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

@end
