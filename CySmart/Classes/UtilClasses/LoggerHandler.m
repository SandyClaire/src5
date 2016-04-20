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


#define LOGGER_KEY @"Logger_Data"
#define DATE_DATA_KEY @"Date_Log"

#import "LoggerHandler.h"
#import "CoreDataHandler.h"
#import "Utilities.h"


/*!
 *  @class LoggerHandler
 *
 *  @discussion Class to handle data logging operations
 *
 */
@interface LoggerHandler ()
{
    NSMutableArray *DateLogArray;
    CoreDataHandler *loggerDataHandler;
}

@end

@implementation LoggerHandler
@synthesize Logger;

+ (id)LogManager {
    static LoggerHandler *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init])
    {
        if (!loggerDataHandler)
        {
            loggerDataHandler = [[CoreDataHandler alloc] init];
        }
    }
    return self;
}


/*!
 *  @method LogData:
 *
 *  @discussion Method to add entries from different services
 *
 */

-(void)LogData:(NSString*)logData
{
    NSString *logEntry = [NSString stringWithFormat:@"[%@]%@%@",[self getDateAndTime],DATE_SEPARATOR,logData];
    [loggerDataHandler saveDate:[Utilities getCurrentDate] andEvent:logEntry];
}

/*!
 *  @method getCurrentDayLoggedData
 *
 *  @discussion Method to get the current day logged data
 *
 */

-(NSArray *) getCurrentDayLoggedData
{
    return [loggerDataHandler getEventsForDate:[Utilities getCurrentDate]];
}


/*!
 *  @method getDateAndTime
 *
 *  @discussion Method that returns the current time
 *
 */

-(NSString *)getDateAndTime
{
    NSDate *today = [NSDate date];
    NSString *currentTime ;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:DATE_FORMAT];
    currentTime = [dateFormatter stringFromDate:today];

    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:TIME_FORMAT];
    currentTime = [currentTime stringByAppendingString:[NSString stringWithFormat:@"|%@",[timeFormatter stringFromDate:today]]];
    return currentTime;
}

/*!
 *  @method getDateFromString:
 *
 *  @discussion Method that convert the date format
 *
 */

-(NSDate*)getDateFromString:(NSString *)dateInString
{
    dateInString = [dateInString stringByReplacingOccurrencesOfString:@"|" withString:@" "];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:[NSString stringWithFormat:@"%@ %@",DATE_FORMAT,TIME_FORMAT]];
    return [dateFormatter dateFromString:dateInString];
}

/*!
 *  @method removePastLogData
 *
 *  @discussion Method to remove the data older than one week
 *
 */
-(void)removePastLogData
{
    NSArray *dayArray = [loggerDataHandler getDatesOfLoggedData];
    
    if([dayArray count])
    {
        for (NSString *dateString in dayArray)
        {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"dd-MM-yyyy"];
            NSDate *pastDate = [[NSDate alloc] init];
            pastDate = [dateFormatter dateFromString:dateString];
            
            if([self daysDifferent:pastDate] >= 7)
            {
                [loggerDataHandler removeLoggedEventsForDate:dateString];
            }
        }
    }
}

/*!
 *  @method daysDifferent:
 *
 *  @discussion Method to calculate the day difference between a particular day and present day
 *
 */

-(NSInteger)daysDifferent:(NSDate *)pastDate
{
    if(pastDate == nil)
        return 0;
    
    NSDate *currentDate = [self getDateFromString:[self getDateAndTime]];
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                        fromDate:pastDate
                                                          toDate:currentDate
                                                         options:0];
    return [components day];
}

@end
