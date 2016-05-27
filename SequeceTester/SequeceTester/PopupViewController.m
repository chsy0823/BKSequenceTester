//
//  PopupViewController.m
//  SequeceTester
//
//  Created by SuhyongChoi on 2016. 5. 27..
//  Copyright © 2016년 bako. All rights reserved.
//

#import "PopupViewController.h"

@interface PopupViewController ()

@end

@implementation PopupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setModalPresentationStyle:UIModalPresentationCustom];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)okClicked:(id)sender {
    
    [self dismissViewControllerAnimated:NO completion:^(void) {
        [self.delegate setIP:self.ip.text Port:self.port.text];
    }];
}
- (IBAction)cancelClicked:(id)sender {
    
    [self dismissViewControllerAnimated:NO completion:nil];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
