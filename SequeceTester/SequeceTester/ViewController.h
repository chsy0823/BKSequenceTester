//
//  ViewController.h
//  SequeceTester
//
//  Created by SuhyongChoi on 2016. 5. 21..
//  Copyright © 2016년 bako. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MFSideMenu.h"

@interface ViewController : UIViewController<UITableViewDataSource, UITableViewDelegate> {
    NSMutableArray *packetArray;
}

@property (nonatomic, weak) IBOutlet UITableView *tableView;

- (IBAction)showMenu:(id)sender;
@end

