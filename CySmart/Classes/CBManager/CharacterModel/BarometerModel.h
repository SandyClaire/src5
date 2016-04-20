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


#import <Foundation/Foundation.h>
#import "CBManager.h"


@interface BarometerModel : NSObject

/*!
 *  @property sensorScanIntervalString
 *
 *  @discussion The barometer sensor scan interval
 *
 */

@property (strong,nonatomic) NSString *sensorScanIntervalString;

/*!
 *  @property pressureValueString
 *
 *  @discussion The barometer pressure value
 *
 */
@property (strong,nonatomic) NSString *pressureValueString;

/*!
 *  @property sensorTypeString
 *
 *  @discussion The barometer sensor type
 *
 */
@property (strong,nonatomic) NSString *sensorTypeString;

/*!
 *  @property filterTypeConfigurationString
 *
 *  @discussion The barometer filter type
 *
 */
@property (strong,nonatomic) NSString *filterTypeConfigurationString;

/*!
 *  @method stopUpdate
 *
 *  @discussion Method to stop update
 *
 */

-(void) stopUpdate;

/*!
 *  @method getCharacteristicsForBarometerService:
 *
 *  @discussion Method to get characteristics for barometer service
 *
 */
-(void) getCharacteristicsForBarometerService:(CBService *)service;

/*!
 *  @method updateValueForPressure
 *
 *  @discussion Method to set notification for barometer reading
 *
 */
-(void) updateValueForPressure;

/*!
 *  @method getValuesForBarometerCharacteristics:
 *
 *  @discussion Method to get values for barometer characteristics
 *
 */

-(void) getValuesForBarometerCharacteristics:(CBCharacteristic *)characteristic;

/*!
 *  @method readValueForCharacteristics
 *
 *  @discussion Method to read values for sensortype, scan interval and data accumulation characteristic
 *
 */

-(void) readValueForCharacteristics;

@end
