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
#import "RGBModel.h"
#import "CBManager.h"
#import "LoggerHandler.h"

/*!
 *  @class RGBModel
 *
 *  @discussion Class to handle the RGB service related operations
 *
 */

@interface RGBModel()<cbCharacteristicManagerDelegate>
{
    void (^cbCharacteristicHandler)(BOOL success, NSError *error);
    void (^cbWriteCharacteristicHandler)(BOOL success, NSError *error);
    CBCharacteristic *RGBCharacteristics;
    BOOL isWriteSuccess;
}

@end

@implementation RGBModel

@synthesize  redColor;
@synthesize  greenColor;
@synthesize  blueColor;
@synthesize  intensity;


- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self startDiscoverChar];
        
    }
    return self;
}


/*!
 *  @method startDiscoverChar
 *
 *  @discussion Discovers the specified characteristics of a service..
 */

-(void)startDiscoverChar
{
    isWriteSuccess = YES ;
    [[CBManager sharedManager] setCbCharacteristicDelegate:self];
    
    for(CBService *service in [[CBManager sharedManager] myPeripheral].services)
    {
        if([service.UUID isEqual:RGB_SERVICE_UUID] || [service.UUID isEqual:CUSTOM_RGB_SERVICE_UUID] )
        {
            [[[CBManager sharedManager] myPeripheral] discoverCharacteristics:nil forService:service];
        }
    }
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
    if ([[[CBManager sharedManager] myService].UUID isEqual:RGB_SERVICE_UUID] || [[[CBManager sharedManager] myService].UUID isEqual:CUSTOM_RGB_SERVICE_UUID])
    {
        for (CBCharacteristic *aChar in [[CBManager sharedManager] myService].characteristics)
        {
            if ([aChar.UUID isEqual:RGB_CHARACTERISTIC_UUID] || [aChar.UUID isEqual:CUSTOM_RGB_CHARACTERISTIC_UUID] )
            {
                [[[CBManager sharedManager] myPeripheral] setNotifyValue:NO  forCharacteristic:aChar];
            }
        }
    }
}

/*!
 *  @method writeColor:BColor:GColor:Intensity:With
 *
 *  @discussion Write RGB colors and current intensity to specified characteristic.
 */

-(void)writeColor:(NSInteger)rColor BColor:(NSInteger)bColor GColor:(NSInteger)gColor Intensity:(NSInteger)lIntensity With:(void (^) (BOOL success, NSError *error))handler
{
    cbWriteCharacteristicHandler = handler ;
    
    if(isWriteSuccess && RGBCharacteristics)
    {
        self.redColor = rColor ;
        self.greenColor = gColor;
        self.blueColor = bColor;
        self.intensity = lIntensity;
        
        uint8_t val[] = {rColor,gColor,bColor,lIntensity}; //enter the value which you want to write.

        NSData *valData = [NSData dataWithBytes:(void*)&val length:sizeof(val)];
        [[[CBManager sharedManager] myPeripheral] writeValue:valData forCharacteristic:RGBCharacteristics type:CBCharacteristicWriteWithResponse];
        [self logColourData:valData];
        isWriteSuccess = NO;
    }
}


#pragma mark - CBManagerDelagate methods

/*!
 *  @method peripheral: didDiscoverCharacteristicsForService: error:
 *
 *  @discussion Method invoked when characteristics are discovered for a service
 *
 */

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:RGB_SERVICE_UUID] || [service.UUID isEqual:CUSTOM_RGB_SERVICE_UUID])
    {
        for (CBCharacteristic *aChar in service.characteristics){
            if ([aChar.UUID isEqual:RGB_CHARACTERISTIC_UUID] || [aChar.UUID isEqual:CUSTOM_RGB_CHARACTERISTIC_UUID])
            {
                RGBCharacteristics = aChar;
                [[[CBManager sharedManager] myPeripheral] readValueForCharacteristic:aChar];
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
    [self updateValues:characteristic error:error];
}


/*!
 *  @method peripheral: didWriteVlueForCharacteristic: error:
 *
 *  @discussion Write acknowledgement for RGB colors and intensity to specified characteristic.
 */

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
    if(error)
    {
        isWriteSuccess = NO ;
        cbWriteCharacteristicHandler(NO,error);
    }
    else
    {
        isWriteSuccess = YES ;
        cbWriteCharacteristicHandler(YES,error);
    }
    
    [self logWriteStatusWithError:error];
}

/*!
 *  @method updateValues:error
 *
 *  @discussion Initially get value from specified characteristic.
 */

-(void)updateValues:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error == nil)
    {
        if (([characteristic.UUID isEqual:RGB_CHARACTERISTIC_UUID] || [characteristic.UUID isEqual:CUSTOM_RGB_CHARACTERISTIC_UUID]) && characteristic.value)
        {
            NSData *data = [characteristic value];      // 1
            const uint8_t *reportData = [data bytes];
            
            self.redColor =  reportData[0];
            self.greenColor =  reportData[1];
            self.blueColor =  reportData[2];
            self.intensity =  reportData[3];
            
            cbCharacteristicHandler(YES,nil);
        }
        else
        {
            cbCharacteristicHandler(NO,error);
        }
    }
    else
    {
        cbCharacteristicHandler(NO,error);
    }
}

/*!
 *  @method logColourData:
 *
 *  @discussion Method to log the colour written to the device
 *
 */
-(void) logColourData:(NSData *)data
{
    [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:RGB_SERVICE_UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:RGB_CHARACTERISTIC_UUID] descriptor:nil operation:[NSString stringWithFormat:@"%@%@ %@",WRITE_REQUEST,DATA_SEPERATOR,[Utilities convertDataToLoggerFormat:data]]];
    
}

-(void) logWriteStatusWithError:(NSError *)error
{
    if (error == nil)
    {
        [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:RGB_SERVICE_UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:RGB_CHARACTERISTIC_UUID] descriptor:nil operation:[NSString stringWithFormat:@"%@- %@",WRITE_REQUEST_STATUS,WRITE_SUCCESS]];
    }
    else
    {
       [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:RGB_SERVICE_UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:RGB_CHARACTERISTIC_UUID] descriptor:nil operation:[NSString stringWithFormat:@"%@- %@%@",WRITE_REQUEST_STATUS,WRITE_ERROR,[error.userInfo objectForKey:NSLocalizedDescriptionKey]]];
    }
}


@end
