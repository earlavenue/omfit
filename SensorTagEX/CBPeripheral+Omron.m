//
//  CBPeripheral+Omron.m
//  SensorTagEX
//
//  Created by Alex Cone on 4/3/14.
//  Copyright (c) 2014 Texas Instruments. All rights reserved.
//

#import "CBPeripheral+Omron.h"

@implementation CBPeripheral (Omron)

- (BOOL)hasService:(NSString *)serviceUUID {
    BOOL found = NO;
    for (CBService *s in self.services) {
        if ([s.UUID isEqual:[CBUUID UUIDWithString:serviceUUID]])  {
            found = YES;
        }
    }
    return found;
}

- (BOOL)isOmronDevice {
    return [self hasService:@"ECBE3980-C9A2-11E1-B1BD-0002A5D5C51B"];
}

- (BOOL)isSensorTagDevice {
    return [self hasService:@"F000AA00-0451-4000-B000-000000000000"];
}

- (NSString *)displayName {
    if ([self isOmronDevice]) {
        return [NSString stringWithFormat:@"Omron Device [%@]",self.name];
    }
    if ([self isSensorTagDevice]) {
        return [NSString stringWithFormat:@"SensorTag Device [%@]",self.name];
    }
    return [NSString stringWithFormat:@"Unknown Device [%@]",self.name];
}

@end
