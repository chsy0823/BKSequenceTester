//
//  CommandList.h
//  SequeceTester
//
//  Created by SuhyongChoi on 2016. 5. 27..
//  Copyright © 2016년 bako. All rights reserved.
//

#ifndef CommandList_h
#define CommandList_h

#define ConnectTCPIP    0
#define DisconnectTCPIP 1
#define ConnectBT       2
#define DisconnectBT    3
#define SPKWavePlay     4
#define RCVWavePlay     5
#define EARWavePlay     6
#define LoopBackONOFF   7
#define VIBRATE         8
#define VolumeUP        9
#define VolumeDOWN      10

#define READY               0
#define ACK                 1
#define SEND_MESSAGE        13
#define GETINFO             13
#define SEND_BTINFO         14
#define REMOTE_CONNECTBT    21
#define REMOTE_DISCONNECTBT 22
#define REMOTE_SPKWavePlay  101
#define REMOTE_RCVWavePlay  102
#define REMOTE_EARWavePlay  103
#define REMOTE_LOOPBACKMODE 104
#define REMOTE_VIBMOTOR     106
#define REMOTE_SETVOLUME    108
#define BTSPKWAV            109


#endif /* CommandList_h */
