/*
 *  bleUtility.m
 *
 * Created by Ole Andreas Torvmark on 10/2/12.
 * Copyright (c) 2012 Texas Instruments Incorporated - http://www.ti.com/
 * ALL RIGHTS RESERVED
 */

#import "BLEUtility.h"

@implementation BLEUtility

+(void)writeCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID data:(NSData *)data {
    // Sends data to BLE peripheral to process HID and send EHIF command to PC
    NSLog(@"writeCharacteristic....");
    for ( CBService *service in peripheral.services ) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]]) {
            for ( CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]]) {
                    /* EVERYTHING IS FOUND, WRITE characteristic ! */
                    [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                    
                }
            }
        }
    }
}

+(void)writeCharacteristic:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *)cCBUUID data:(NSData *)data {
    // Sends data to BLE peripheral to process HID and send EHIF command to PC
    int foundsomehting = 0, cnts = 0;
    for ( CBService *service in peripheral.services ) {
        NSLog(@"writeCharacteristic FIND sCBUUID %@ then cCBUUID %@\n IN service.characteristics %@\n", sCBUUID, cCBUUID, service.characteristics);
        if ([service.UUID isEqual:sCBUUID]) {
            for ( CBCharacteristic *characteristic in service.characteristics ) {
                cnts++;
                if ([characteristic.UUID isEqual:cCBUUID]) {
                    /* EVERYTHING IS FOUND, WRITE characteristic ! */
                    foundsomehting++;
                    [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                    NSLog(@"writeCharacteristic (found) UUID %@ data %u\nservice.characteristics %@", characteristic.UUID, *(uint8_t *)[data bytes], service.characteristics);
                } else {
                    ; // NSLog(@"writeCharacteristic (no match) %@ != %@", characteristic.UUID, cCBUUID);
                }
//                 if ( [CBUUID UUIDWithString:[self.d.setupData valueForKey:service.characteristics]] )
            }
        }
    }
    NSLog(@"writeCharacteristic matched %d/%d...\n\tperipheral %@\n\tsCBUUID %@\n\tcCBUUID %@\n\tdata %u\n",
          foundsomehting, cnts, peripheral, sCBUUID, cCBUUID, *(uint8_t *)[data bytes]);
}



+(void)readCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID {
    for ( CBService *service in peripheral.services ) {
        if([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]]) {
            for ( CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]]) {
                    /* Everything is found, read characteristic ! */
                    [peripheral readValueForCharacteristic:characteristic];
                    NSLog(@"readCharacteristic: %@ +++ %@", service.UUID, characteristic.UUID);
                }
            }
        }
    }
}

+(void)readCharacteristic:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *)cCBUUID {
    NSLog(@"readCharacteristic: searching for...\n\t%@\n\t%@\nin %@\n\n", sCBUUID, cCBUUID, peripheral);
    for ( CBService *service in peripheral.services ) {
        NSLog(@"readCharacteristic: is... %@ == %@ ?\nservice.characteristics: %@\n", service.UUID, cCBUUID, service.characteristics);
        if([service.UUID isEqual:sCBUUID]) {
            for ( CBCharacteristic *characteristic in service.characteristics ) {
                NSLog(@"readCharacteristic: and is... %@ == %@ ?", characteristic.UUID, cCBUUID);
                if ([characteristic.UUID isEqual:cCBUUID]) {
                    /* Everything is found, read characteristic ! */
                    [peripheral readValueForCharacteristic:characteristic];
                    NSLog(@"readCharacteristic: found\n\t%@\n\t%@\n", service.UUID, characteristic.UUID);
                }
            }
        }
    }
}

+(void)setNotificationForCharacteristic:(CBPeripheral *)peripheral sUUID:(NSString *)sUUID cUUID:(NSString *)cUUID enable:(BOOL)enable {
    NSLog(@"setNotificationForCharacteristic: searching for...\n\t%@\n\t%@\nin %@", sUUID, cUUID, peripheral);
    for ( CBService *service in peripheral.services ) {
        NSLog(@"setNotificationForCharacteristic: %@/+/%@/%@\n", service.UUID, sUUID, cUUID);
        if ([service.UUID isEqual:[CBUUID UUIDWithString:sUUID]]) {
            for (CBCharacteristic *characteristic in service.characteristics ) {
                NSLog(@"setNotificationForCharacteristic: -+-> %@ == %@\n", characteristic.UUID, cUUID);
               if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:cUUID]]) {
                    /* Everything is found, set notification ! */
                    [peripheral setNotifyValue:enable forCharacteristic:characteristic];
                }
            }
        }
    }
}

+(void)setNotificationForCharacteristic:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *)cCBUUID enable:(BOOL)enable {
    NSLog(@"setNotificationForCharacteristic:: searching for...\n\t%@\n\t%@\nin %@", sCBUUID, cCBUUID, peripheral);
    for ( CBService *service in peripheral.services ) {
        if ([service.UUID isEqual:sCBUUID]) {
            NSLog(@"setNotificationForCharacteristic:: %@ in \n%@", service.UUID, service.characteristics);
            for (CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:cCBUUID]) {
                    NSLog(@"setNotificationForCharacteristic:: %@ -> %@",
                        service.UUID, characteristic.UUID);
                    /* Everything is found, set notification ! */
                    [peripheral setNotifyValue:enable forCharacteristic:characteristic];
                }
            }
        }
    }
}


+(bool) isCharacteristicNotifiable:(CBPeripheral *)peripheral sCBUUID:(CBUUID *)sCBUUID cCBUUID:(CBUUID *) cCBUUID {
    for ( CBService *service in peripheral.services ) {
        if ([service.UUID isEqual:sCBUUID]) {
            for (CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:cCBUUID]) {
                    if (characteristic.properties & CBCharacteristicPropertyNotify) return YES;
                    else return NO;
                }
            }
        }
    }
    return NO;
}


+(CBUUID *) expandToTIUUID:(CBUUID *)sourceUUID {
    CBUUID *expandedUUID = [CBUUID UUIDWithString:TI_BASE_LONG_UUID];
    unsigned char expandedUUIDBytes[16];
    unsigned char sourceUUIDBytes[2];
    [expandedUUID.data getBytes:expandedUUIDBytes];
    [sourceUUID.data getBytes:sourceUUIDBytes];
    expandedUUIDBytes[2] = sourceUUIDBytes[0];
    expandedUUIDBytes[3] = sourceUUIDBytes[1];
    expandedUUID = [CBUUID UUIDWithData:[NSData dataWithBytes:expandedUUIDBytes length:16]];
    return expandedUUID;
}


+(NSString *) CBUUIDToString:(CBUUID *)inUUID {
    unsigned char i[16];
    [inUUID.data getBytes:i];
    if (inUUID.data.length == 2) {
        return [NSString stringWithFormat:@"%02hhx%02hhx",i[0],i[1]];
    }
    else {
        uint32_t g1 = ((i[0] << 24) | (i[1] << 16) | (i[2] << 8) | i[3]);
        uint16_t g2 = ((i[4] << 8) | (i[5]));
        uint16_t g3 = ((i[6] << 8) | (i[7]));
        uint16_t g4 = ((i[8] << 8) | (i[9]));
        uint16_t g5 = ((i[10] << 8) | (i[11]));
        uint32_t g6 = ((i[12] << 24) | (i[13] << 16) | (i[14] << 8) | i[15]);
        return [NSString stringWithFormat:@"%08x-%04hx-%04hx-%04hx-%04hx%08x",g1,g2,g3,g4,g5,g6];
    }
    return nil;
}


  
@end
