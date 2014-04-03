/*
 *  deviceSelector.m
 *
 * Created by Ole Andreas Torvmark on 10/2/12.
 * Copyright (c) 2012 Texas Instruments Incorporated - http://www.ti.com/
 * ALL RIGHTS RESERVED
 */

#import "deviceSelector.h"
#import "CBPeripheral+Omron.h"

@interface deviceSelector ()

@end

@implementation deviceSelector
@synthesize m,nDevices,sensorTags;



- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.m = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
        self.nDevices = [[NSMutableArray alloc]init];
        self.sensorTags = [[NSMutableArray alloc]init];
        self.title = @"SensorTag (omron) Example";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated {
    self.m.delegate = self;

}





#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return sensorTags.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:[NSString stringWithFormat:@"%ld_Cell",(long)indexPath.row]];
    CBPeripheral *p = [self.sensorTags objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@",p.displayName];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"(UUID: %@)",CFUUIDCreateString(nil, p.UUID)];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

-(NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        if (self.sensorTags.count > 1 )
            return [NSString stringWithFormat:@"%lu BLE Devices Found",(unsigned long)self.sensorTags.count];
        else
            return [NSString stringWithFormat:@"%lu BLE Device Found",(unsigned long)self.sensorTags.count];
    }
    
    return @"";
}

-(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 150.0f;
}

#pragma mark - Table view delegate

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CBPeripheral *p = [self.sensorTags objectAtIndex:indexPath.row];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    BLEDevice *d = [[BLEDevice alloc]init];
    
    d.p = p;
    d.manager = self.m;
    d.setupData = [self makeSensorTagConfiguration];
    
    SensorTagApplicationViewController *vC = [[SensorTagApplicationViewController alloc]initWithStyle:UITableViewStyleGrouped andSensorTag:d];
    [self.navigationController pushViewController:vC animated:YES];
    
}




#pragma mark - CBCentralManager delegate

-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state != CBCentralManagerStatePoweredOn) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"BLE not supported !" message:[NSString stringWithFormat:@"CoreBluetooth return state: %ld",central.state] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
    else {
        [central scanForPeripheralsWithServices:nil options:nil];
    }
}




-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"Found a BLE Device: %@", peripheral);
    
    /* iOS 6.0 bug workaround : connect to device before displaying UUID !
       The reason for this is that the CFUUID .UUID property of CBPeripheral
       here is null the first time an unkown (never connected before in any app)
       peripheral is connected. So therefore we connect to all peripherals we find.
    */
    
    peripheral.delegate = self;
    [central connectPeripheral:peripheral options:nil];
    
    [self.nDevices addObject:peripheral];
    
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [peripheral discoverServices:nil];
}

#pragma  mark - CBPeripheral delegate

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    BOOL replace = NO;
//    BOOL found = NO;
//    NSLog(@"Services scanned !");
//    [self.m cancelPeripheralConnection:peripheral];
//    for (CBService *s in peripheral.services) {
//        NSLog(@"Service found : %@",s.UUID);
//        if ([s.UUID isEqual:[CBUUID UUIDWithString:@"F000AA00-0451-4000-B000-000000000000"]])  {
//            NSLog(@"This is a SensorTag !");
//            found = YES;
//        }
//        if ([s.UUID isEqual:[CBUUID UUIDWithString:@"ECBE3980-C9A2-11E1-B1BD-0002A5D5C51B"]])  {
//            NSLog(@"This is OMRON !");
//            found = YES;
//        }
//    }
//    if (found) {
        // Match if we have this device from before
        for (int ii=0; ii < self.sensorTags.count; ii++) {
            CBPeripheral *p = [self.sensorTags objectAtIndex:ii];
            if ([p isEqual:peripheral]) {
                    [self.sensorTags replaceObjectAtIndex:ii withObject:peripheral];
                    replace = YES;
                }
            }
        if (!replace) {
            [self.sensorTags addObject:peripheral];
        }
//    }
    [self.tableView reloadData];
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didUpdateNotificationStateForCharacteristic %@ error = %@",characteristic,error);
}

-(void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didWriteValueForCharacteristic %@ error = %@",characteristic,error);
}


#pragma mark - SensorTag configuration

-(NSMutableDictionary *) makeSensorTagConfiguration {
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    // First we set ambient temperature
    [d setValue:@"1" forKey:@"Ambient temperature active"];
    // Then we set IR temperature
    [d setValue:@"1" forKey:@"IR temperature active"];
    // Append the UUID to make it easy for app
    [d setValue:@"F000AA00-0451-4000-B000-000000000000"  forKey:@"IR temperature service UUID"];
    [d setValue:@"F000AA01-0451-4000-B000-000000000000"  forKey:@"IR temperature data UUID"];
        [d setValue:@"IR temperature data UUID"  forKey:@"F000AA01-0451-4000-B000-000000000000"];
    [d setValue:@"F000AA02-0451-4000-B000-000000000000"  forKey:@"IR temperature config UUID"];
    // Then we setup the accelerometer
    [d setValue:@"1" forKey:@"Accelerometer active"];
    [d setValue:@"500" forKey:@"Accelerometer period"];
    [d setValue:@"F000AA10-0451-4000-B000-000000000000"  forKey:@"Accelerometer service UUID"];
    [d setValue:@"F000AA11-0451-4000-B000-000000000000"  forKey:@"Accelerometer data UUID"];
    [d setValue:@"F000AA12-0451-4000-B000-000000000000"  forKey:@"Accelerometer config UUID"];
    [d setValue:@"F000AA13-0451-4000-B000-000000000000"  forKey:@"Accelerometer period UUID"];
    
    //Then we setup the rH sensor
    [d setValue:@"1" forKey:@"Humidity active"];
    [d setValue:@"F000AA20-0451-4000-B000-000000000000"   forKey:@"Humidity service UUID"];
    [d setValue:@"F000AA21-0451-4000-B000-000000000000" forKey:@"Humidity data UUID"];
    [d setValue:@"F000AA22-0451-4000-B000-000000000000" forKey:@"Humidity config UUID"];
    
    //Then we setup the magnetometer
    [d setValue:@"1" forKey:@"Magnetometer active"];
    [d setValue:@"500" forKey:@"Magnetometer period"];
    [d setValue:@"F000AA30-0451-4000-B000-000000000000" forKey:@"Magnetometer service UUID"];
    [d setValue:@"F000AA31-0451-4000-B000-000000000000" forKey:@"Magnetometer data UUID"];
    [d setValue:@"F000AA32-0451-4000-B000-000000000000" forKey:@"Magnetometer config UUID"];
    [d setValue:@"F000AA33-0451-4000-B000-000000000000" forKey:@"Magnetometer period UUID"];
    
    //Then we setup the barometric sensor
    [d setValue:@"1" forKey:@"Barometer active"];
    [d setValue:@"F000AA40-0451-4000-B000-000000000000" forKey:@"Barometer service UUID"];
    [d setValue:@"F000AA41-0451-4000-B000-000000000000" forKey:@"Barometer data UUID"];
    [d setValue:@"F000AA42-0451-4000-B000-000000000000" forKey:@"Barometer config UUID"];
    [d setValue:@"F000AA43-0451-4000-B000-000000000000" forKey:@"Barometer calibration UUID"];
    
    [d setValue:@"1" forKey:@"Gyroscope active"];
    [d setValue:@"F000AA50-0451-4000-B000-000000000000" forKey:@"Gyroscope service UUID"];
    [d setValue:@"F000AA51-0451-4000-B000-000000000000" forKey:@"Gyroscope data UUID"];
    [d setValue:@"F000AA52-0451-4000-B000-000000000000" forKey:@"Gyroscope config UUID"];
    
    
    // OMRON
    
    // First we set Omron is here
    [d setValue:@"1" forKey:@"OMRON active"];
    [d setValue:@"ECBE3980-C9A2-11E1-B1BD-0002A5D5C51B" forKey:@"Omron WLB Service"];
    
    [d setValue:@"00002a37-0000-1000-8000-00805f9b34fb" forKey:@"HEART_RATE_MEASUREMENT"];
    [d setValue:@"00002902-0000-1000-8000-00805f9b34fb" forKey:@"CLIENT_CHARACTERISTIC_CONFIG"];
    
    [d setValue:@"DB5B55E0-AEE7-11E1-965E-0002A5D5C51B" forKey:@"OMRON_WLBLOCKCOMOUT01"];
    [d setValue:@"E0B8A060-AEE7-11E1-92F4-0002A5D5C51B" forKey:@"OMRON_WLBLOCKCOMOUT02"];
    [d setValue:@"0AE12B00-AEE8-11E1-A192-0002A5D5C51B" forKey:@"OMRON_WLBLOCKCOMOUT03"];
    [d setValue:@"10E1BA60-AEE8-11E1-89E5-0002A5D5C51B" forKey:@"OMRON_WLBLOCKCOMOUT04"];
    
    [d setValue:@"49123040-AEE8-11E1-A74D-0002A5D5C51B" forKey:@"OMRON_WLBLOCKCOMIN01"];
    [d setValue:@"4D0BF320-AEE8-11E1-A0D9-0002A5D5C51B" forKey:@"OMRON_WLBLOCKCOMIN02"];
    [d setValue:@"5128CE60-AEE8-11E1-B84B-0002A5D5C51B" forKey:@"OMRON_WLBLOCKCOMIN03"];
    [d setValue:@"560F1420-AEE8-11E1-8184-0002A5D5C51B" forKey:@"OMRON_WLBLOCKCOMIN04"];
    
    [d setValue:@"B305B680-AEE7-11E1-A730-0002A5D5C51B" forKey:@"OMRON_WLSYSTEM_VALUE"];
        [d setValue:@"OMRON_WLSYSTEM_VALUE" forKey:@"B305B680-AEE7-11E1-A730-0002A5D5C51B"]; // for reverse lookup? tj
//    [d setValue:@"ECBE3980-C9A2-11E1-B1BD-0002A5D5C51B" forKey:@"OMRON_WLB_SERVICE"];
    [d setValue:@"09FCF88E-E5F4-45CB-B436-06131BBD51ED" forKey:@"TEST_SERVICE"];
    [d setValue:@"23AB78DA-982C-49A0-9734-06BB749D0F96" forKey:@"TEST_SERIAL_SPEED"];
    
    [d setValue:@"00001800-0000-1000-8000-00805F9B34FB" forKey:@"Generic Access Service"];
    [d setValue:@"00001801-0000-1000-8000-00805F9B34FB" forKey:@"Generic Attributes Service"];
    [d setValue:@"0000180A-0000-1000-8000-00805F9B34FB" forKey:@"Device Information Service"];
    
    [d setValue:@"09FCF88E-E5F4-45CB-B436-06131BBD51ED" forKey:@"Test Service"];
    
    // Generic Access Service Characteristics.
    [d setValue:@"00002A00-0000-1000-8000-00805F9B34FB" forKey:@"Device Name String"];
    [d setValue:@"00002A01-0000-1000-8000-00805F9B34FB" forKey:@"External Appearance"];
    [d setValue:@"00002A02-0000-1000-8000-00805F9B34FB" forKey:@"Peripheral Privacy Flag"];
    [d setValue:@"00002A03-0000-1000-8000-00805F9B34FB" forKey:@"Reconnection Address"];
    [d setValue:@"00002A04-0000-1000-8000-00805F9B34FB" forKey:@"Peripheral Preferred Connection Parameters"];
    
    // Generic AttributesService Characteristics.
    [d setValue:@"00002A05-0000-1000-8000-00805F9B34FB" forKey:@"Service Changed"];
    
    // Device Information Service Characteristics.
    [d setValue:@"00002A23-0000-1000-8000-00805F9B34FB" forKey:@"System ID"];
    [d setValue:@"00002A24-0000-1000-8000-00805F9B34FB" forKey:@"Model Number String"];
    [d setValue:@"00002A25-0000-1000-8000-00805F9B34FB" forKey:@"Serial Number String"];
    [d setValue:@"00002A26-0000-1000-8000-00805F9B34FB" forKey:@"Firware Revision String"];
    [d setValue:@"00002A27-0000-1000-8000-00805F9B34FB" forKey:@"Hardware Revision String"];
    [d setValue:@"00002A28-0000-1000-8000-00805F9B34FB" forKey:@"Software Revision String"];
    [d setValue:@"00002A29-0000-1000-8000-00805F9B34FB" forKey:@"Manufacturer Name String"];
    [d setValue:@"00002A2A-0000-1000-8000-00805F9B34FB" forKey:@"IEEE 11073-20601 Regulatory Certification Data List"];
    
    // OmronSleep Design Service Characteristics.
    [d setValue:@"B305B680-AEE7-11E1-A730-0002A5D5C51B" forKey:@"Omron wlsystemValueUUID"];	//read/write 17 bytes  send encryption here

    [d setValue:@"DB5B55E0-AEE7-11E1-965E-0002A5D5C51B" forKey:@"Omron wlblockcomout01UUID"];  //write 16 bytes
    [d setValue:@"E0B8A060-AEE7-11E1-92F4-0002A5D5C51B" forKey:@"Omron wlblockcomout02UUID"];  //write 16 bytes
    [d setValue:@"0AE12B00-AEE8-11E1-A192-0002A5D5C51B" forKey:@"Omron wlblockcomout03UUID"];  //write 16 bytes
    [d setValue:@"10E1BA60-AEE8-11E1-89E5-0002A5D5C51B" forKey:@"Omron wlblockcomout04UUID"];  //write 16 bytes
    
    [d setValue:@"49123040-AEE8-11E1-A74D-0002A5D5C51B" forKey:@"Omron wlblockcomin01UUID"];	  //read 16 bytes
    [d setValue:@"4D0BF320-AEE8-11E1-A0D9-0002A5D5C51B" forKey:@"Omron wlblockcomin02UUID"];  //read 16 bytes
    [d setValue:@"5128CE60-AEE8-11E1-B84B-0002A5D5C51B" forKey:@"Omron wlblockcomin03UUID"];	//read 16 bytes
    [d setValue:@"560F1420-AEE8-11E1-8184-0002A5D5C51B" forKey:@"Omron wlblockcomin04UUID"];	//read 16 bytes
    [d setValue:@"8858EB40-AEE8-11E1-BB67-0002A5D5C51B" forKey:@"Omron wlstreamcomValueUUID"]; //read 16 bytes To be used in the future

// Done wellness
    
//    NSLog(@"%@",d);
    
    return d;
}

@end
