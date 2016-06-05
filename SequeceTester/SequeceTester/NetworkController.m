//
//  NetworkController.m
//  SequeceTester
//
//  Created by SuhyongChoi on 2016. 5. 26..
//  Copyright © 2016년 bako. All rights reserved.
//

#import "NetworkController.h"

static NetworkController *singletonInstance;

@implementation NetworkController
@synthesize currentObserverName;

+ (NetworkController *)sharedInstance {
    
    @synchronized(self) {
        if (!singletonInstance) {
            NSLog(@"NetworkController has not been initialized. Either place one in your storyboard or initialize one in code");
            singletonInstance = [[NetworkController alloc]init];
            [singletonInstance initNetworkController];
        }
    }
    
    return singletonInstance;
    
}

- (void)initNetworkController {
    
    notificationCenter = [NSNotificationCenter defaultCenter];
    connected = false;
    //[self parsePacket:[self makePacekt:002 Data:@"1q2w3e4r"]];
    
}
- (BOOL)isConnectedToServer {
    
    return connected;
}

- (NSString*)makePacekt:(int)command Data:(NSString*)data {
    
    int length = (int)[data length] + 2;
    NSString *dataPacket = [NSString stringWithFormat:@":%03d%03d%@\r\n",command,length,data];
    
    return dataPacket;
}

- (NSDictionary*)parsePacket:(NSString*)inputData {
    
    
    if([inputData length] > 3) {
        NSString *STX = [inputData substringToIndex:1];
        NSString *CRLF = [inputData substringFromIndex:[inputData length]-2];
        
        if([STX isEqualToString:@":"] && [CRLF isEqualToString:@"\r\n"]) {
            NSString *command = [inputData substringWithRange:NSMakeRange(1, 3)];
            NSString *length = [inputData substringWithRange:NSMakeRange(4, 3)];
            NSString *data = [inputData substringWithRange:NSMakeRange(7, [inputData length]-9)];
            
            //NSLog(@"stx = %@ CRLF = %@ command = %@ length = %@ data = %@",STX, CRLF, command, length, data);
            NSLog(@"parse ok!");
            NSDictionary *dict = @{@"command":command,
                     @"data":data, @"length":length, @"fullData":inputData
                     };
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self sendCommand:ACK Data:command];
            });

            
            return dict;
        }
    }
    
    return nil;
    
}

- (void)setServerWithIP:(NSString*)ip Port:(int)port {
    
    serverIP = ip;
    serverPort = port;
    
    [self TcpClientInitialise];
}

- (void)disconnect {
    
    [InputStream close];
    [OutputStream close];
    connected = false;
    
    NSDictionary *result = @{@"interruptFlag":@true, @"msg":@"TCP stream disconnected", @"data":@""};
    [notificationCenter postNotificationName:currentObserverName object:self userInfo:result];
}

- (void)sendCommand:(int)command Data:(NSString*)data{
    
    NSString *packet = [self makePacekt:command Data:data];
    [OutputData appendData:[packet dataUsingEncoding:NSUTF8StringEncoding]];
    
    if(OutputStream.hasSpaceAvailable) {
        [self sendData];
    }
//    const uint8_t * rawstring = (const uint8_t *)[packet UTF8String];
//    [OutputStream write:rawstring maxLength:strlen(rawstring)];
    
}

- (void)sendData {
    
    if(OutputData.length) {
        NSInteger wLength = [OutputStream write:(const uint8_t*)OutputData.bytes maxLength:OutputData.length];
        if ( wLength > 0 )
            [OutputData replaceBytesInRange:NSMakeRange(0, wLength) withBytes:NULL length:0];
    }

}

//*******************************************
//*******************************************
//********** TCP CLIENT INITIALISE **********
//*******************************************
//*******************************************
- (void)TcpClientInitialise
{
    NSLog(@"Tcp Client Initialise.. Connect to ip = %@, port = %d",serverIP, serverPort);
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)serverIP, serverPort, &readStream, &writeStream);
    
    OutputData = [NSMutableData data];
    
    InputStream = (__bridge NSInputStream *)readStream;
    OutputStream = (__bridge NSOutputStream *)writeStream;
    
    [InputStream setDelegate:self];
    [OutputStream setDelegate:self];
    
    [InputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [OutputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [InputStream open];
    [OutputStream open];
}


//****************************************
//****************************************
//********** TCP CLIENT RECEIVE **********
//****************************************
//****************************************
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)StreamEvent
{
    NSDictionary *result;
    
    switch (StreamEvent)
    {
        case NSStreamEventOpenCompleted:
            NSLog(@"TCP Client - Stream opened");
            result = @{@"interruptFlag":@true, @"msg":@"Connected to server ok!", @"data":@""};
            connected = true;
            break;
            
        case NSStreamEventHasBytesAvailable:
            if (theStream == InputStream)
            {
                uint8_t buffer[1024];
                int len;
                
                while ([InputStream hasBytesAvailable])
                {
                    len = [InputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0)
                    {
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        
                        if (nil != output)
                        {
                            NSLog(@"TCP Client - Server sent: %@", output);
                            
                            if([self parsePacket:output] !=nil) {
                                result = @{@"interruptFlag":@false, @"msg":@"success", @"data":[self parsePacket:output]};
                                
                                [notificationCenter postNotificationName:currentObserverName object:self userInfo:result];
                            }
                        }
                    }
                }
            }
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"TCP Client - Can't connect to the host");
            result = @{@"interruptFlag":@true, @"msg":@"Can't connect to the host", @"data":@""};
            
            [notificationCenter postNotificationName:currentObserverName object:self userInfo:result];
            break;
            
        case NSStreamEventEndEncountered:
            NSLog(@"TCP Client - End encountered");
            result = @{@"interruptFlag":@true, @"msg":@"TCP stream end", @"data":@""};
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            
            connected = false;
            break;
            
        case NSStreamEventNone:
            NSLog(@"TCP Client - None event");
            break;
            
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"TCP Client - Has space available event");
            [self sendData];
            break;
            
        default:
            NSLog(@"TCP Client - Unknown event");
    }
    
}

@end
