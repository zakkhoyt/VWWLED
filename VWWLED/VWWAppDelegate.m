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
@property (weak) IBOutlet NSPopUpButton *serailPortsPopup;

@end

@implementation VWWAppDelegate


- (void)applicationDdFinishLaunching:(NSNotification *)aNotification
{
    
}
- (IBAction)reloadButtonAction:(id)sender {
    if(self.arduinoController == nil){
        self.arduinoController = [[VWWArduinoController alloc]init];
        self.arduinoController.delegate = self;
    }
    
    
    [self.arduinoController refreshSerialList];
    NSArray *serialPorts = self.arduinoController.getSerialPorts;
    
    [self.serailPortsPopup removeAllItems];

    [self.serailPortsPopup addItemsWithTitles:serialPorts];
}

- (IBAction)serailPopupAction:(NSPopUpButton*)sender {
    
    
    NSMenuItem *menuItem = sender.itemArray[sender.indexOfSelectedItem];
    NSString *serialPort = menuItem.title;
    
    //NSString *serialPort = self.arduinoController.getSerialPorts[index];
    
    
    NSLog(@"serailPort: %@", serialPort);
    [self.arduinoController connectToSerialPort:serialPort withBaudRate:250000];
    
}
- (IBAction)sendStringAction:(id)sender {
    [self.arduinoController writeString:@"Hello"];
}

- (IBAction)sendDataAction:(id)sender {
}

- (IBAction)resetButtonAction:(id)sender {
    [self.arduinoController sendResetCommand];
}


#pragma mark VWWArduinoControllerDelegate

-(void)arduinoController:(VWWArduinoController*)sender didEncounterError:(NSError*)error{
    NSLog(@"%s: ERROR: %@", __PRETTY_FUNCTION__, error.description);
}

-(void)arduinoController:(VWWArduinoController*)sender didReceiveString:(NSString*)inString{
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, inString);
}

-(void)arduinoController:(VWWArduinoController*)sender didReceiveData:(NSData*)inData{
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, inData.description);
}



@end
