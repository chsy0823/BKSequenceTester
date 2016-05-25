//
//  ConsoleTableViewCell.h
//  SequeceTester
//
//  Created by SuhyongChoi on 2016. 5. 25..
//  Copyright © 2016년 bako. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ConsoleTableViewCell : UITableViewCell


@property (nonatomic,weak) IBOutlet UILabel *indicator;
@property (nonatomic,weak) IBOutlet UILabel *contentLabel;
@end
