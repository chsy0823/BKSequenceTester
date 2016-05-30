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
    //[self parsePacket:[self makePacekt:002 Data:@"1q2w3e4r"]];
    
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
            
            [self sendCommand:ACK Data:command];
            
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

- (void)sendCommand:(int)command Data:(NSString*)data{
    
    NSString *packet = [self makePacekt:command Data:data];
    
    const uint8_t * rawstring = (const uint8_t *)[packet UTF8String];
    [OutputStream write:rawstring maxLength:strlen(rawstring)];
    
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
    
    InputStream = (__bridge NSInputStream *)readStream;
    OutputStream = (__bridge NSOutputStream *)writeStream;
    
    [InputStream setDelegate:self];
    [OutputStream setDelegate:self];
    
    [InputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [OutputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [InputStream open];
    [OutputStream open];
}


//**********************************
//**********************************
//********** SENDING DATA **********
//**********************************
//**********************************

- (void)sendData:(NSString*)sendData {
    
    NSData *data = [[NSData alloc] initWithData:[sendData dataUsingEncoding:NSASCIIStringEncoding]];
    [OutputStream write:[data bytes] maxLength:[data length]];    //<<Returns actual number of bytes sent - check if trying to send a large number of bytes as they may well not have all gone in this write and will need sending once there is a hasspaceavailable event
}


//****************************************
//****************************************
//********** TCP CLIENT RECEIVE **********
//****************************************
//****************************************
- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)StreamEvent
{
    
    switch (StreamEvent)
    {
        case NSStreamEventOpenCompleted:
            NSLog(@"TCP Client - Stream opened");
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
                            
                            NSDictionary *result = [self parsePacket:output];
                            
                            if(result != nil)
                                [notificationCenter postNotificationName:currentObserverName object:self userInfo:result];
                        }
                        
                        //Send some data (large block where the write may not actually send all we request it to send)
                        int ActualOutputBytes = [OutputStream write:[OutputData bytes] maxLength:[OutputData length]];
                        
                        if (ActualOutputBytes >= [OutputData length])
                        {
                            //It was all sent
                            OutputData = nil;
                        }
                        else
                        {
                            //Only partially sent
                            [OutputData replaceBytesInRange:NSMakeRange(0, ActualOutputBytes) withBytes:NULL length:0];        //Remove sent bytes from the start
                        }
                    }
                }
            }
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"TCP Client - Can't connect to the host");
            break;
            
        case NSStreamEventEndEncountered:
            NSLog(@"TCP Client - End encountered");
            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            break;
            
        case NSStreamEventNone:
            NSLog(@"TCP Client - None event");
            break;
            
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"TCP Client - Has space available event");
            if (OutputData != nil)
            {
                //Send rest of the packet
                int ActualOutputBytes = [OutputStream write:[OutputData bytes] maxLength:[OutputData length]];
                
                if (ActualOutputBytes >= [OutputData length])
                {
                    //It was all sent
                    OutputData = nil;
                }
                else
                {
                    //Only partially sent
                    [OutputData replaceBytesInRange:NSMakeRange(0, ActualOutputBytes) withBytes:NULL length:0];        //Remove sent bytes from the start
                }
            }
            break;
            
        default:
            NSLog(@"TCP Client - Unknown event");
    }
    
}

@end
