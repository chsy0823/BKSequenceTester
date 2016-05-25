//
//  PacketObject.h
//  SequeceTester
//
//  Created by SuhyongChoi on 2016. 5. 25..
//  Copyright © 2016년 bako. All rights reserved.
//

#import <Foundation/Foundation.h>
#define RX 1
#define TX 2

@interface PacketObject : NSObject

@property (nonatomic, assign) NSInteger RXTX;
@property (nonatomic, strong) NSString *contents;

@end
