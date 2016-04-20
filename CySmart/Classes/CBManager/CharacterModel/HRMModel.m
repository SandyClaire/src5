/*
 * Copyright Cypress Semiconductor Corporation, 2014-2015 All rights reserved.
 *
 * This software, associated documentation and materials ("Software") is
 * owned by Cypress Semiconductor Corporation ("Cypress") and is
 * protected by and subject to worldwide patent protection (UnitedStates and foreign), United States copyright laws and international
 * treaty provisions. Therefore, unless otherwise specified in a separate license agreement between you and Cypress, this Software
 * must be treated like any other copyrighted material. Reproduction,
 * modification, translation, compilation, or representation of this
 * Software in any other form (e.g., paper, magnetic, optical, silicon)
 * is prohibited without Cypress's express written permission.
 *
 * Disclaimer: THIS SOFTWARE IS PROVIDED AS-IS, WITH NO WARRANTY OF ANY
 * KIND, EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
 * NONINFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE. Cypress reserves the right to make changes
 * to the Software without notice. Cypress does not assume any liability
 * arising out of the application or use of Software or any product or
 * circuit described in the Software. Cypress does not authorize its
 * products for use as critical components in any products where a
 * malfunction or failure may reasonably be expected to result in
 * significant injury or death ("High Risk Product"). By including
 * Cypress's product in a High Risk Product, the manufacturer of such
 * system or application assumes all risk of such use and in doing so
 * indemnifies Cypress against all liability.
 *
 * Use of this Software may be limited by and subject to the applicable
 * Cypress software license agreement.
 *
 *
 */

#import "HRMModel.h"
#import "CBManager.h"

/*!
 *  @class HRMModel
 *
 *  @discussion Class to handle the heart rate measurement service related operations
 *
 */

@interface HRMModel()<cbCharacteristicManagerDelegate>
{
    void (^cbCharacteristicHandler)(BOOL success, NSError *error);
    void (^cbCharacteristicDiscoverHandler)(BOOL success, NSError *error);
}

@end


@implementation HRMModel

@synthesize bpmValue;
@synthesize sensorLocation;
@synthesize RR_Interval;
@synthesize EnergyExpended;

/*!
 *  @method startDiscoverChar:
 *
 *  @discussion Discovers the specified characteristics of a service..
 */


-(void)startDiscoverChar:(void (^) (BOOL success, NSError *error))handler
{
    cbCharacteristicDiscoverHandler = handler;
    [[CBManager sharedManager] setCbCharacteristicDelegate:self];
    [[[CBManager sharedManager] myPeripheral] discoverCharacteristics:nil forService:[[CBManager sharedManager] myService]];
}

/*!
 *  @method updateCharacteristicWithHandler:
 *
 *  @discussion Sets notifications or indications for the value of a specified characteristic.
 */

-(void)updateCharacteristicWithHandler:(void (^) (BOOL success, NSError *error))handler
{
    cbCharacteristicHandler = handler;
}


/*!
 *  @method stopUpdate
 *
 *  @discussion Stop notifications or indications for the value of a specified characteristic.
 */

-(void)stopUpdate
{
    cbCharacteristicHandler = nil;
    if ([[[CBManager sharedManager] myService].UUID isEqual:HRM_HEART_RATE_SERVICE_UUID])
    {
        for (CBCharacteristic *aChar in [[CBManager sharedManager] myService].characteristics)
        {
            if ([aChar.UUID isEqual:HRM_NOTIFICATIONS_CHARACTERISTIC_UUID])
            {
                if (aChar.isNotifying)
                {
                    [[[CBManager sharedManager] myPeripheral] setNotifyValue:NO  forCharacteristic:aChar];
                    [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:HRM_HEART_RATE_SERVICE_UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:HRM_NOTIFICATIONS_CHARACTERISTIC_UUID] descriptor:nil operation:STOP_NOTIFY];
                }
                
                cbCharacteristicDiscoverHandler(YES,nil);
                break;
            }
        }
    }
}


#pragma mark - CBCharecteristicManger

/*!
 *  @method peripheral: didDiscoverCharacteristicsForService: error:
 *
 *  @discussion Method invoked when characteristics are discovered for a service
 *
 */

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:HRM_HEART_RATE_SERVICE_UUID]){
        for (CBCharacteristic *aChar in service.characteristics){
            if ([aChar.UUID isEqual:HRM_NOTIFICATIONS_CHARACTERISTIC_UUID]){
                
                [[[CBManager sharedManager] myPeripheral] setNotifyValue:YES forCharacteristic:aChar];
                [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:HRM_HEART_RATE_SERVICE_UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:HRM_NOTIFICATIONS_CHARACTERISTIC_UUID] descriptor:nil operation:START_NOTIFY];
                
                cbCharacteristicDiscoverHandler(YES,nil);
            }
            else if([aChar.UUID isEqual:HRM_BODY_LOCATION_CHARACTERISTIC_UUID])
            {
                [[[CBManager sharedManager] myPeripheral] readValueForCharacteristic:aChar];
                [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:HRM_HEART_RATE_SERVICE_UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:HRM_BODY_LOCATION_CHARACTERISTIC_UUID] descriptor:nil operation:READ_REQUEST];
            }
        }
    }
    
}

/*!
 *  @method peripheral: didUpdateValueForCharacteristic: error:
 *
 *  @discussion Method invoked when the characteristic value changes
 *
 */

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
     if(error == nil)
     {
         if ([characteristic.UUID isEqual:HRM_NOTIFICATIONS_CHARACTERISTIC_UUID])
         {
             [self getHeartBPMData:characteristic error:error];
         }
         else if ([characteristic.UUID isEqual:HRM_BODY_LOCATION_CHARACTERISTIC_UUID])
         {
             [self getBodyLocation:characteristic];
         }
             
        cbCharacteristicHandler(YES,nil);

     }
     else
     {
         cbCharacteristicHandler(NO,error);
     }
}


/*!
 *  @method getHeartBPMData:error
 *
 *  @discussion   Method to get the Heart Rate Measurement Value , Energy Expended, RR-Interval
 *
 */

// Instance method to get the heart rate BPM information
- (void) getHeartBPMData:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // Get the BPM //
    // https://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.heart_rate_measurement.xml //
    
    // Convert the contents of the characteristic value to a data-object //
    NSData *data = [characteristic value];
    
    // Get the byte sequence of the data-object //
    const uint8_t *reportData = [data bytes];
    
    // Initialise the offset variable //
    NSUInteger offset = 1;
    // Initialise the bpm variable //
    uint16_t bpm = 0;
    
    
    // Next, obtain the first byte at index 0 in the array as defined by reportData[0] and mask out all but the 1st bit //
    // The result returned will either be 0, which means that the 2nd bit is not set, or 1 if it is set //
    // If the 2nd bit is not set, retrieve the BPM value at the second byte location at index 1 in the array //
    if ((reportData[0] & 0x01) == 0) {
        // Retrieve the BPM value for the Heart Rate Monitor
        bpm = reportData[1];
        
        offset = offset + 1; // Plus 1 byte //
    }
    else {
        // If the second bit is set, retrieve the BPM value at second byte location at index 1 in the array and //
        // convert this to a 16-bit value based on the host’s native byte order //
        bpm = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[1]));
        
        offset =  offset + 2; // Plus 2 bytes //
    }
    self.bpmValue = bpm;//[NSString stringWithFormat:@"%d",bpm];
    
    // Determine if EE data is present //
    // If the 3rd bit of the first byte is 1 this means there is EE data //
    // If so, increase offset with 2 bytes //
    if (reportData[0] & 0x08)
    {
        uint16_t expendedEnergy = 0;
        expendedEnergy = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[offset]));
        offset =  offset + 2; // Plus 2 bytes //
        self.EnergyExpended = [NSString stringWithFormat:@"%d",expendedEnergy];
    }
    else
    {
        self.EnergyExpended = @"0";
    }
    
    // Determine if RR-interval data is present //
    // If the 4th bit of the first byte is 1 this means there is RR data //
    if (reportData[0] & 0x10)
    {
    
        // The number of RR-interval values is total bytes left / 2 (size of uint16) //
        
        NSUInteger length = [data length];
        NSUInteger count = (length - offset)/2;
        uint16_t RRinterval = 0 ;
        for (int i = 0; i < count; i++) {
            
            // The unit for RR interval is 1/1024 seconds //
            RRinterval = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[offset]));
            RRinterval = ((double)RRinterval / 1024.0 ) * 1000.0;
            offset = offset + 2; // Plus 2 bytes //
            self.RR_Interval = [NSString stringWithFormat:@"%d",RRinterval];
        }
    }
    
    [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:HRM_HEART_RATE_SERVICE_UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:HRM_NOTIFICATIONS_CHARACTERISTIC_UUID] descriptor:nil operation:[NSString stringWithFormat:@"%@%@ %@",NOTIFY_RESPONSE,DATA_SEPERATOR,[Utilities convertDataToLoggerFormat:data]]];
}

/*!
 *  @method getSensorContactStatus:
 *
 *  @discussion   Instance method to get the body location of the device is available or not
 *
 */

-(BOOL)getSensorContactStatus:(CBCharacteristic *)characteristic
{
    NSData *data = [characteristic value];
    const uint8_t *reportData = [data bytes];
    if((reportData[0] & 0x02) == 4)
        return YES;
    return NO;
}

/*!
 *  @method getBodyLocation:
 *
 *  @discussion   Instance method to get the body location of the device
 *
 */
//
- (void) getBodyLocation:(CBCharacteristic *)characteristic
{
    NSData *sensorData = [characteristic value];
    uint8_t *bodyData = (uint8_t *)[sensorData bytes];
    if (bodyData ) {
        uint8_t bodyLocation = bodyData[0];
        NSString *Sensloc = @"";
        switch (bodyLocation)
        {
            case 0:
                Sensloc = OTHER; break;
            case 1:
                Sensloc = CHEST; break;
            case 2:
                Sensloc = WRIST; break;
            case 3:
                Sensloc = FINGER; break;
            case 4:
                Sensloc = HAND; break;
            case 5:
                Sensloc = EAR_LOBE; break;
            case 6:
                Sensloc = FOOT; break;
            default:
                break;
        }
        self.sensorLocation = Sensloc;
    }
    else {
        self.sensorLocation = LOCATION_NA;
    }
    
     [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:characteristic.service.UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:characteristic.UUID] descriptor:nil operation:[NSString stringWithFormat:@"%@%@ %@",READ_RESPONSE,DATA_SEPERATOR,[Utilities convertDataToLoggerFormat:sensorData]]];
}




@end
