//
//  VWWAppDelegate.m
//  VWWLED
//
//  Created by Zakk Hoyt on 4/19/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "VWWAppDelegate.h"
#import "VWWArduinoController.h"
@interface VWWAppDelegate () <VWWArduinoControllerDelegate>
@property (weak) IBOutlet NSButton *reloadConnectionButton;
@property (strong) VWWArduinoController *arduinoController;
@property (weak) IBOutlet NSPopUpButton *serialPortsPopup;
@property (weak) IBOutlet NSTextField *baudTextField;

@end

@implementation VWWAppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if(self.arduinoController == nil){
        self.arduinoController = [[VWWArduinoController alloc]init];
        self.arduinoController.delegate = self;
    }
    
    [self reloadButtonAction:nil];  
    
}
- (IBAction)reloadButtonAction:(id)sender {

    
    [self.arduinoController refreshSerialList];
    NSArray *serialPorts = self.arduinoController.getSerialPorts;
    
    [self.serialPortsPopup removeAllItems];

    [self.serialPortsPopup addItemsWithTitles:serialPorts];
}

- (IBAction)serialPopupAction:(NSPopUpButton*)sender {
    
    
    NSMenuItem *menuItem = sender.itemArray[sender.indexOfSelectedItem];
    NSString *serialPort = menuItem.title;
    
    //NSString *serialPort = self.arduinoController.getSerialPorts[index];
    
    
    NSLog(@"serialPort: %@", serialPort);
    [self.arduinoController connectToSerialPort:serialPort withBaudRate:250000];
    
}
- (IBAction)sendStringAction:(id)sender {
    [self.arduinoController writeString:@"Hello"];
}

- (IBAction)sendDataAction:(id)sender {
    
    NSString *str = @"data";
    NSData* data = [str dataUsingEncoding:NSUTF8StringEncoding];
    [self.arduinoController writeData:data];
}
- (IBAction)sendByteAction:(id)sender {
    uint8_t bytes[] = {'b', 'y', 't', 'e'};
    [self.arduinoController writeByte:bytes];
}

- (IBAction)resetButtonAction:(id)sender {
    [self.arduinoController sendResetCommand];
}


#pragma mark VWWArduinoControllerDelegate

-(void)arduinoController:(VWWArduinoController*)sender didEncounterError:(NSError*)error{
    NSLog(@"%s: ERROR: %@", __PRETTY_FUNCTION__, error.description);
}

-(void)arduinoController:(VWWArduinoController*)sender didReceiveString:(NSString*)inString{
    NSLog(@"%s: \n%@", __PRETTY_FUNCTION__, inString);
}

-(void)arduinoController:(VWWArduinoController*)sender didReceiveData:(NSData*)inData{
//    NSLog(@"%s: %@", __PRETTY_FUNCTION__, inData.description);

    
//    NSString* str = [[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding];
//    NSLog(@"%s: \n%@", __PRETTY_FUNCTION__, str);
}

- (IBAction)currentButtonAction:(id)sender {
    NSString *serialPort = self.arduinoController.currentSerialPort;
    NSUInteger baudRate = self.arduinoController.currentBaudRate;
    NSLog(@"Current serial port: %@ @ %ld", serialPort, (long)baudRate);
}

- (IBAction)closeButtonAction:(id)sender {
    [self.arduinoController disconnectFromCurrentSerialPort];
}
- (IBAction)changeBaudButton:(id)sender {
    NSInteger value = self.baudTextField.integerValue;
    [self.arduinoController setBaudRateForCurrentSerialPort:value];
}

@end
