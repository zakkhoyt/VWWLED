//
//  VWWArduinoController.m
//  VWWLED
//
//  Created by Zakk Hoyt on 4/19/14.
//  Copyright (c) 2014 Zakk Hoyt. All rights reserved.
//

#import "VWWArduinoController.h"
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#include <IOKit/serial/ioss.h>
#include <sys/ioctl.h>



static NSString *VWWArdruinoErrorDomain = @"VWWArduinoControler";



@interface VWWArduinoController ()
@property (nonatomic, strong) NSMutableArray *serialPorts;
@property (nonatomic) int serialFileDescriptor; // file handle to the serial port
@property (nonatomic) struct termios gOriginalTTYAttrs; // Hold the original termios attributes so we can reset them on quit ( best practice )
@property (nonatomic) bool readThreadRunning;
@property (nonatomic) NSTextStorage *storage;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@end

@implementation VWWArduinoController


#pragma mark Public methods

-(id)init{
    self = [super init];
    if(self){
        _serialPorts = [@[]mutableCopy];
        _serialQueue = dispatch_queue_create("com.vaporwarewolf.arduinocontroller.serial", NULL);
    }
    return self;
}


// Enumeration
-(void)refreshSerialList{
    io_object_t serialPort;
	io_iterator_t serialPortIterator;
	
	// remove everything from the pull down list
	[self.serialPorts removeAllObjects];
	
	// ask for all the serial ports
	IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kIOSerialBSDServiceValue), &serialPortIterator);
	
	// loop through all the serial ports and add them to the array
	while ((serialPort = IOIteratorNext(serialPortIterator))) {
        NSString *serialPortString = (NSString*)CFBridgingRelease(IORegistryEntryCreateCFProperty(serialPort, CFSTR(kIOCalloutDeviceKey),  kCFAllocatorDefault, 0));
        [self.serialPorts addObject:serialPortString];
		IOObjectRelease(serialPort);
	}
	
}
-(NSArray*)getSerialPorts{
    return [NSArray arrayWithArray:self.serialPorts];
}

// Connections
-(BOOL)connectToSerialPort:(NSString*)serialPort withBaudRate:(NSUInteger)baudRate{
	int success;
	
	// close the port if it is already open
	if (self.serialFileDescriptor != -1) {
		close(self.serialFileDescriptor);
		self.serialFileDescriptor = -1;
		
		// wait for the reading thread to die
		while(self.readThreadRunning);
		
		// re-opening the same port REALLY fast will fail spectacularly... better to sleep a sec
		sleep(0.5);
	}
	
	// c-string path to serial-port file
	const char *bsdPath = [serialPort cStringUsingEncoding:NSUTF8StringEncoding];
	
	// Hold the original termios attributes we are setting
	struct termios options;
	
	// receive latency ( in microseconds )
	unsigned long mics = 3;
	
	// error message string
	NSMutableString *errorMessage = nil;
	
	// open the port
	//     O_NONBLOCK causes the port to open without any delay (we'll block with another call)
	self.serialFileDescriptor = open(bsdPath, O_RDWR | O_NOCTTY | O_NONBLOCK );
	
	if (self.serialFileDescriptor == -1) {
		// check if the port opened correctly
		errorMessage = [@"Error: couldn't open serial port" mutableCopy];
	} else {
		// TIOCEXCL causes blocking of non-root processes on this serial-port
		success = ioctl(self.serialFileDescriptor, TIOCEXCL);
		if ( success == -1) {
			errorMessage = [@"Error: couldn't obtain lock on serial port" mutableCopy];
		} else {
			success = fcntl(self.serialFileDescriptor, F_SETFL, 0);
			if ( success == -1) {
				// clear the O_NONBLOCK flag; all calls from here on out are blocking for non-root processes
				errorMessage = [@"Error: couldn't obtain lock on serial port" mutableCopy];
			} else {
				// Get the current options and save them so we can restore the default settings later.
				success = tcgetattr(self.serialFileDescriptor, &_gOriginalTTYAttrs);
				if ( success == -1) {
					errorMessage = [@"Error: couldn't get serial attributes" mutableCopy];
				} else {
					// copy the old termios settings into the current
					//   you want to do this so that you get all the control characters assigned
					options = self.gOriginalTTYAttrs;
					
					/*
					 cfmakeraw(&options) is equivilent to:
					 options->c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
					 options->c_oflag &= ~OPOST;
					 options->c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
					 options->c_cflag &= ~(CSIZE | PARENB);
					 options->c_cflag |= CS8;
					 */
					cfmakeraw(&options);
					
					// set tty attributes (raw-mode in this case)
					success = tcsetattr(self.serialFileDescriptor, TCSANOW, &options);
					if ( success == -1) {
						errorMessage = [@"Error: coudln't set serial attributes" mutableCopy];
					} else {
						// Set baud rate (any arbitrary baud rate can be set this way)
						success = ioctl(self.serialFileDescriptor, IOSSIOSPEED, &baudRate);
						if ( success == -1) {
							errorMessage = [@"Error: Baud Rate out of bounds" mutableCopy];
						} else {
							// Set the receive latency (a.k.a. don't wait to buffer data)
							success = ioctl(self.serialFileDescriptor, IOSSDATALAT, &mics);
							if ( success == -1) {
								errorMessage = [@"Error: coudln't set serial latency" mutableCopy];
							}
						}
					}
				}
			}
		}
	}
	
	// make sure the port is closed if a problem happens
	if ((self.serialFileDescriptor != -1) && (errorMessage != nil)) {
		close(self.serialFileDescriptor);
		self.serialFileDescriptor = -1;
	}
    
    // Fire up thread for receiving
    [self performSelectorInBackground:@selector(incomingTextUpdateThread:) withObject:[NSThread currentThread]];
	// TODO: Convert from NSThread to GCD
//    dispatch_async(self.serialQueue, ^{
////        [self incomingTextUpdateThread:<#(NSThread *)#>]
//    });
    
    
    
    if(errorMessage){
        NSError *error = [self error:errorMessage code:-1];
        [self errorOccurred:error];
    }

	return errorMessage == nil;
}
-(BOOL)setBaudRateForCurrentSerialPort:(NSUInteger)baudRate{
    return NO;
}
-(BOOL)disconnectFromCurrentSerialPort{
    return NO;
}
-(NSString*)currentSerialPort{
    return @"TODO";
}
-(NSUInteger)currentBaudRate{
    return 0;
}


// Writing
-(void)writeString:(NSString*)outString{
    if(self.serialFileDescriptor!=-1) {
		write(self.serialFileDescriptor, [outString cStringUsingEncoding:NSUTF8StringEncoding], [outString length]);
	} else {
        
		// make sure the user knows they should select a serial port
//		[self appendToIncomingText:@"\n ERROR:  Select a Serial Port from the pull-down menu\n"];
	}
}
-(void)writeByte:(uint8_t*)val{
    
}

// Reading


// Other
-(void)sendResetCommand{
    // set and clear DTR to reset an arduino
	struct timespec interval = {0,100000000}, remainder;
	if(self.serialFileDescriptor!=-1) {
		ioctl(self.serialFileDescriptor, TIOCSDTR);
		nanosleep(&interval, &remainder); // wait 0.1 seconds
		ioctl(self.serialFileDescriptor, TIOCCDTR);
	}
}


#pragma mark Private methods


// This selector/function will be called as another thread...
//  this thread will read from the serial port and exits when the port is closed
- (void)incomingTextUpdateThread: (NSThread *) parentThread {
	

	@autoreleasepool {
        

        // mark that the thread is running
        self.readThreadRunning = TRUE;
        
        const int BUFFER_SIZE = 100;
        char byte_buffer[BUFFER_SIZE]; // buffer for holding incoming data
        int numBytes=0; // number of bytes read during read
        NSString *text; // incoming text from the serial port
        
        // assign a high priority to this thread
        [NSThread setThreadPriority:1.0];
        
        // this will loop unitl the serial port closes
        while(TRUE) {
            // read() blocks until some data is available or the port is closed
            numBytes = (int)read(self.serialFileDescriptor, byte_buffer, BUFFER_SIZE); // read up to the size of the buffer
            if(numBytes>0) {
                // create an NSString from the incoming bytes (the bytes aren't null terminated)
                text = [NSString stringWithCString:byte_buffer encoding:NSUTF8StringEncoding];
                
                // this text can't be directly sent to the text area from this thread
                //  BUT, we can call a selctor on the main thread.
                [self receivedString:text];
            } else {
                break; // Stop the thread if there is an error
            }
        }
        
        // make sure the serial port is closed
        if (self.serialFileDescriptor != -1) {
            close(self.serialFileDescriptor);
            self.serialFileDescriptor = -1;
        }
        
        // mark that the thread has quit
        self.readThreadRunning = FALSE;
	
    }

}



-(void)receivedString:(NSString*)inString{
    if(self.delegate &&
       [self.delegate respondsToSelector:@selector(arduinoController:didReceiveString:)]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate arduinoController:self didReceiveString:inString];
        });
        
    }
}

-(NSError*)error:(NSString *)message code:(NSInteger)code{
    NSDictionary *errorInfo = @{NSLocalizedDescriptionKey: message};
    return [NSError errorWithDomain:VWWArdruinoErrorDomain code:code userInfo:errorInfo];
}
-(void)errorOccurred:(NSError*)error{
    if(self.delegate &&
       [self.delegate respondsToSelector:@selector(arduinoController:didEncounterError:)]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate arduinoController:self didEncounterError:error];
        });
    }
}


@end
