//
//  PopupViewController.h
//  SequeceTester
//
//  Created by SuhyongChoi on 2016. 5. 27..
//  Copyright © 2016년 bako. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PopupDelegate;

@interface PopupViewController : UIViewController

@property (nonatomic, weak) IBOutlet UITextField *ip;
@property (nonatomic, weak) IBOutlet UITextField *port;
@property (nonatomic,weak) id<PopupDelegate>delegate;

- (IBAction)okClicked:(id)sender;
- (IBAction)cancelClicked:(id)sender;

@end

@protocol PopupDelegate <NSObject>

@required
- (void)setIP:(NSString*)ip Port:(NSString*)port;

@end
