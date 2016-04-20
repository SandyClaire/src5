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

#import "GATTDBServiceListViewController.h"
#import "ServiceListTableViewCell.h"
#import "ResourceHandler.h"
#import "CBManager.h"
#import "ResourceHandler.h"
#import "UIView+Toast.h"
#import "CarouselViewController.h"


#define CHARACTERISTIC_LIST_SEGUE       @"CharacteristicsListSegue"
#define SERVICE_CELL_IDENTIFIER         @"ServiceListCell"


/*!
 *  @class GATTDBServiceListViewController
 *
 *  @discussion Class to handle the available services list table
 *
 */
@interface GATTDBServiceListViewController ()<UITableViewDataSource,UITableViewDelegate>
{
    NSArray *servicesArray;
}

@property (weak, nonatomic) IBOutlet UITableView *serviceListTableView;

@end

@implementation GATTDBServiceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[super navBarTitleLabel] setText:GATT_DB];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (![self.navigationController.viewControllers containsObject:self])
    {
        [self handleCharacteristicNotifications];
    }
}

#pragma mark -TableView Datasource


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    servicesArray = [[[CBManager sharedManager] foundServices] copy]; // Getting the available services
    return servicesArray.count;
    
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ServiceListTableViewCell *currentCell=[tableView dequeueReusableCellWithIdentifier:SERVICE_CELL_IDENTIFIER];
    
    if (currentCell == nil)
    {
        currentCell = [[ServiceListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SERVICE_CELL_IDENTIFIER];
    }

    CBService *service = [servicesArray objectAtIndex:[indexPath row]];
    
    /*  Display the service name  */
     NSString *serviceNameString = [ResourceHandler getServiceNameForUUID:service.UUID];
    [currentCell setServiceName:serviceNameString];
    return currentCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0f;
}

/*!
 *  @method tableView: willDisplayCell: forRowAtIndexPath:
 *
 *  @discussion Method to set the cell properties
 *
 */
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    /* Setting cell background */
    UIImageView *cellBGImageView=[[UIImageView alloc]initWithFrame:cell.bounds];
    [cellBGImageView setImage:[UIImage imageNamed:CELL_BG_IMAGE_SMALL]];
    cell.backgroundView=cellBGImageView;
    
}

#pragma mark - TableView Delegate Methods

/*!
 *  @method tableView: didSelectRowAtIndexPath:
 *
 *  @discussion Method to handle the selection of a service
 *
 */
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[CBManager sharedManager] setMyService:[servicesArray objectAtIndex:[indexPath row]]];
    [self performSegueWithIdentifier:CHARACTERISTIC_LIST_SEGUE sender:self];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


/*!
 *  @method handleCharacteristicNotifications
 *
 *  @discussion Method to check whether notification is set for any characteristics and disable the notifications
 *
 */

-(void) handleCharacteristicNotifications
{
    NSString *message = @"";
    BOOL indicationsDisabled = NO, notificationsDisabled = NO;
    
    for (CBService *service in [[CBManager sharedManager] foundServices])
    {
        for (CBCharacteristic *characteristic in service.characteristics) {
            
            if (characteristic.isNotifying){
                
                if ((characteristic.properties & CBCharacteristicPropertyNotify) != 0) {
                    message = NOTIFY_DISABLED;
                    
                    notificationsDisabled = YES;
                    [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:characteristic.service.UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:characteristic.UUID] descriptor:nil operation:STOP_NOTIFY];
                }
                else
                {
                    message = INDICATE_DISABLED;
                    indicationsDisabled = YES;
                    
                    [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:characteristic.service.UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:characteristic.UUID] descriptor:nil operation:STOP_INDICATE];
                }
                
                [[[CBManager sharedManager] myPeripheral] setNotifyValue:NO forCharacteristic:characteristic];
            }
        }
    }
    
    if (indicationsDisabled && notificationsDisabled)
    {
        message = INDICATE_AND_NOTIFY_DISABLED;
    }
    
    // Showing the toast message
    if (![message isEqual:@""])
    {        
        if ([[self.navigationController.viewControllers lastObject] isKindOfClass:[CarouselViewController class]])
        {
            CarouselViewController *carouselVC = [self.navigationController.viewControllers lastObject];
            [carouselVC.view makeToast:message];
        }
    }
}


@end
