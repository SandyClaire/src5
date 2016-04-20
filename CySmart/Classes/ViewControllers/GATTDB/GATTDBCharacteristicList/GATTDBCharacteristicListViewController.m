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

#import "GATTDBCharacteristicListViewController.h"
#import "CharacteristicListTableViewCell.h"
#import "CBManager.h"
#import "ResourceHandler.h"

#define CHARACTERISTIC_SEGUE            @"CharacteristicsListSegue"
#define CHARACTERISTIC_CELL_IDENTIFIER  @"CharacteristicListCell"

/*!
 *  @class GATTDBCharacteristicListViewController
 *
 *  @discussion Class to handle the characteristic list
 *
 */
@interface GATTDBCharacteristicListViewController ()<UITableViewDataSource,UITableViewDelegate,cbCharacteristicManagerDelegate>
{
    NSArray *characteristicArray;
}
@property (weak, nonatomic) IBOutlet UITableView *characteristicListTableView;

@end

@implementation GATTDBCharacteristicListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self getcharcteristicsForService:[[CBManager sharedManager] myService]];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[super navBarTitleLabel] setText:GATT_DB];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark -TableView Datasource


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return characteristicArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CharacteristicListTableViewCell *currentCell=[tableView dequeueReusableCellWithIdentifier:CHARACTERISTIC_CELL_IDENTIFIER];
    
    if (currentCell == nil)
    {
        currentCell = [[CharacteristicListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CHARACTERISTIC_CELL_IDENTIFIER];
    }
    
    /* Display characteristic name and properties  */
    CBCharacteristic *characteristic = [characteristicArray objectAtIndex:[indexPath row]];
    NSString *characteristicName = [ResourceHandler getCharacteristicNameForUUID:characteristic.UUID];
    [currentCell setCharacteristicName:characteristicName andProperties:[self getPropertiesForCharacteristic:characteristic]];
    
    return currentCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80.0f;
}

/*!
 *  @method tableView: willDisplayCell: forRowAtIndexPath:
 *
 *  @discussion Method to set the cell properties
 *
 */

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*  set cell background */
    UIImageView *cellBGImageView=[[UIImageView alloc]initWithFrame:cell.bounds];
    [cellBGImageView setImage:[UIImage imageNamed:CELL_BG_IMAGE]];
    cell.backgroundView=cellBGImageView;
    
}

#pragma mark - TableView Delegates

/*!
 *  @method tableView: didSelectRowAtIndexPath:
 *
 *  @discussion Method to handle the selection of a characteristic
 *
 */

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[CBManager sharedManager] setMyCharacteristic:[characteristicArray objectAtIndex:[indexPath row]]];
    [[CBManager sharedManager] setCharacteristicProperties:[self getPropertiesForCharacteristic:[characteristicArray objectAtIndex:[indexPath row]]]];
    
    [self performSegueWithIdentifier:CHARACTERISTIC_SEGUE sender:self];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/*!
 *  @method getcharcteristicsForService:
 *
 *  @discussion Method to initiate discovering characteristics for service
 *
 */

-(void) getcharcteristicsForService:(CBService *)service
{
    [[CBManager sharedManager] setCbCharacteristicDelegate:self];
    [[[CBManager sharedManager] myPeripheral] discoverCharacteristics:nil forService:service];
}

/*!
 *  @method getPropertiesForCharacteristic:
 *
 *  @discussion Method to get the properties for characteristic
 *
 */
-(NSMutableArray *) getPropertiesForCharacteristic:(CBCharacteristic *)characteristic
{
    
    NSMutableArray *propertyList = [NSMutableArray array];
    
    if ((characteristic.properties & CBCharacteristicPropertyRead) != 0)
    {
        [propertyList addObject:READ];
    }
    if (((characteristic.properties & CBCharacteristicPropertyWrite) != 0) || ((characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) != 0) )
    {
       [propertyList addObject:WRITE];;
    }
    if ((characteristic.properties & CBCharacteristicPropertyNotify) != 0)
    {
       [propertyList addObject:NOTIFY];;
    }
    if ((characteristic.properties & CBCharacteristicPropertyIndicate) != 0)
    {
       [propertyList addObject:INDICATE];;
    }
    
    return propertyList;
}



#pragma mark - CBCharacteristicManagerDelegate Methods

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:[[CBManager sharedManager] myService].UUID])
         {
             characteristicArray = [service.characteristics copy];
             [_characteristicListTableView reloadData];
         }
}




@end
