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


#import "CoreDataHandler.h"
#import "AppDelegate.h"
#import "Logger.h"

#define LOGGER_ENTITY    @"Logger"
#define DATE             @"date"

/*!
 *  @class CoreDataHandler
 *
 *  @discussion Class that handles the operations related to coredata
 *
 */
@implementation CoreDataHandler

/*!
 *  @method saveDate: andEvent:
 *
 *  @discussion Method to write the log to core data
 *
 */

-(void) saveDate:(NSString *)date andEvent:(NSString *)event
{
    AppDelegate *appDelegate= [[UIApplication sharedApplication] delegate];
    Logger *newEntry = [NSEntityDescription insertNewObjectForEntityForName:LOGGER_ENTITY inManagedObjectContext:appDelegate.managedObjectContext];

    newEntry.date = date;
    newEntry.event = event;
    
    NSError *error;
    [appDelegate.managedObjectContext save:&error];
}

/*!
 *  @method getEventsForDate:
 *
 *  @discussion Method that returns all the records that logged in a particular day
 *
 */

-(NSArray *) getEventsForDate:(NSString *) date
{
    AppDelegate *appDelegate= [[UIApplication sharedApplication] delegate];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:LOGGER_ENTITY inManagedObjectContext: appDelegate.managedObjectContext];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date = %@", date];
    [fetchRequest setPredicate:predicate];
    fetchRequest.returnsObjectsAsFaults = NO;
    
    NSError *error = nil;
    NSArray *fetchedObjects = [appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    // Returning only the logged events

    NSMutableArray *loggedEvents = [[NSMutableArray alloc] init];
    
    if (fetchedObjects != nil)
    {
        for (Logger *log in fetchedObjects)
        {
            [loggedEvents addObject:log.event];
        }
    }
    
    return loggedEvents;
}

/*!
 *  @method removeLoggedEventsForDate:
 *
 *  @discussion Method to remove the logs for a particular day
 *
 */

-(void) removeLoggedEventsForDate:(NSString *) date
{
    AppDelegate *appDelegate= [[UIApplication sharedApplication] delegate];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:LOGGER_ENTITY inManagedObjectContext:appDelegate.managedObjectContext];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date = %@", date];
    [fetchRequest setPredicate:predicate];
    fetchRequest.returnsObjectsAsFaults = NO;

    
    NSError *error = nil;
    NSArray *fetchedObjects = [appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    
    if (fetchedObjects != nil)
    {
        for (NSManagedObject *value in fetchedObjects)
        {
            [appDelegate.managedObjectContext deleteObject:value];
        }
    }
    
    [appDelegate.managedObjectContext save:&error];
}

/*!
 *  @method getDatesOfLoggedData
 *
 *  @discussion Method to get the days for which datas are logged
 *
 */

-(NSArray *) getDatesOfLoggedData
{
    AppDelegate *appDelegate= [[UIApplication sharedApplication] delegate];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:LOGGER_ENTITY inManagedObjectContext:appDelegate.managedObjectContext];
    [fetchRequest setEntity:entity];
    // All objects in the backing store are implicitly distinct, but two dictionaries can be duplicates.
    // Since you only want distinct names, only ask for the 'name' property.
    fetchRequest.resultType = NSDictionaryResultType;
    
    [fetchRequest setPropertiesToFetch:@[DATE]];
    fetchRequest.returnsDistinctResults = YES;
    fetchRequest.returnsObjectsAsFaults = NO;

    NSError *error = nil;
    NSArray *fetchedObjects = [appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:&error];
   
    // Returning only the logged events
    
    NSMutableArray *loggedDates = [[NSMutableArray alloc] init];
    
    if (fetchedObjects != nil)
    {
        for (NSDictionary *dict in fetchedObjects)
        {
            [loggedDates addObject:[dict objectForKey:DATE]];
        }
    }

    return loggedDates;
}


@end
