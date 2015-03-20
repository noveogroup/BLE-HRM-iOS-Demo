//
//  BLEHRMController.m
//  BLE-HRM-iOS-Demo
//
//  Created by Alexander Gorbunov on 20/03/15.
//  Copyright (c) 2015 Noveo. All rights reserved.
//


#import "BLEHRMController.h"
#import <CoreBluetooth/CoreBluetooth.h>


static NSString *const bleHRMServiceId = @"0x180D";
static NSString *const bleHRMValueCharacteristicId = @"0x2A37";


@interface BLEHRMController () <CBCentralManagerDelegate, CBPeripheralDelegate>
@property (readwrite) NSInteger heartRate;
@property (nonatomic) CBCentralManager *btManager;
@property (nonatomic) CBPeripheral *connectingPeripheral;
@end


@implementation BLEHRMController

#pragma mark - Object lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _heartRate = -1;
        
        _btManager = [[CBCentralManager alloc] initWithDelegate:self
            queue:dispatch_get_main_queue() options:@{
                CBCentralManagerOptionShowPowerAlertKey:@YES
            }];
    }
    return self;
}

#pragma mark - BT manager callbacks

- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict
{
    NSLog(@"Restoring central manager state.");
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        NSLog(@"Central manager state is 'powered on'.");
        [central scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:bleHRMServiceId]]
            options:nil];
    }
    else {
        NSLog(@"Central manager state is not 'powered on'...");
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
    advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Discovered peripheral %@.", peripheral);
    if (!self.connectingPeripheral && peripheral.state == CBPeripheralStateDisconnected) {
        peripheral.delegate = self;
        self.connectingPeripheral = peripheral;
        [central connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:
    (CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Error while connecting peripheral: %@.", error);
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Connected peripheral %@.", peripheral);
    [peripheral discoverServices:@[[CBUUID UUIDWithString:bleHRMServiceId]]];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error while discovering services: %@.", error);
        return;
    }
    
    NSLog(@"Discovered services for peripheral %@.", peripheral);
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:bleHRMValueCharacteristicId]]
            forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:
    (CBService *)service error:(NSError *)error
{
    if (error) {
        NSLog(@"Error while discovering characteristics: %@.", error);
        return;
    }
    
    NSLog(@"Discovered characteristics for service %@.", service);
    for (CBCharacteristic *characteristic in service.characteristics) {
        if (characteristic.properties & CBCharacteristicPropertyNotify) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error while updating characteristic value: %@.", error);
        return;
    }

    NSLog(@"Updated value for characteristic %@.", characteristic);
    
    NSData *data = characteristic.value;
    
    // Check data format.
    UInt8 flags = *((UInt8 *)data.bytes);
    BOOL valueFormat16 = flags & 0x01;
    
    // Read HR value in given format.
    if (valueFormat16) {
        UInt16 hrValue = *((UInt16 *)(data.bytes + 1));
        self.heartRate = hrValue;
    }
    else {
        UInt8 hrValue = *((UInt8 *)(data.bytes + 1));
        self.heartRate = hrValue;
    }
}

@end
