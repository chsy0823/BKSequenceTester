//
//  NetworkController.h
//  SequeceTester
//
//  Created by SuhyongChoi on 2016. 5. 26..
//  Copyright © 2016년 bako. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommandList.h"

@interface NetworkController : NSObject<NSStreamDelegate> {
    NSString *serverIP;
    int serverPort;
    NSInputStream *InputStream;
    NSOutputStream *OutputStream;
    NSMutableData *OutputData;
    NSNotificationCenter *notificationCenter;
    BOOL connected;
}

@property (nonatomic, strong) NSString *currentObserverName;
+ (NetworkController *)sharedInstance;
- (void)setServerWithIP:(NSString*)ip Port:(int)port;
- (void)sendCommand:(int)command Data:(NSString*)data;
- (void)disconnect;
- (BOOL)isConnectedToServer;
@end
