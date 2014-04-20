//
//  VWWArduinoController.h
//  VWWLED
//
//  Created by Zakk Hoyt on 4/19/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import <Foundation/Foundation.h>


@class VWWArduinoController;

@protocol VWWArduinoControllerDelegate <NSObject>
@required
-(void)arduinoController:(VWWArduinoController*)sender didEncounterError:(NSError*)error;
@optional
-(void)arduinoController:(VWWArduinoController*)sender didReceiveString:(NSString*)inString;
-(void)arduinoController:(VWWArduinoController*)sender didReceiveData:(NSData*)inData;;
@end
@interface VWWArduinoController : NSObject

// Enumeration
-(void)refreshSerialList;
-(NSArray*)getSerialPorts;

// Connections
-(BOOL)connectToSerialPort:(NSString*)serialPort withBaudRate:(NSUInteger)baudRate;
-(BOOL)setBaudRateForCurrentSerialPort:(NSUInteger)baudRate;
-(BOOL)disconnectFromCurrentSerialPort;
-(NSString*)currentSerialPort;
-(NSUInteger)currentBaudRate;


// Writing
-(void)writeString:(NSString*)outString;
-(void)writeByte:(uint8_t*)val;
-(void)writeData:(NSData*)data;

// Reading


// Other
-(void)sendResetCommand;

// Callbacks
@property (nonatomic, weak) id <VWWArduinoControllerDelegate> delegate;


@end
