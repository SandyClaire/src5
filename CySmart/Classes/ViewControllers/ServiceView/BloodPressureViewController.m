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

#import "BloodPressureViewController.h"
#import "BPModel.h"
#import "Constants.h"


/*!
 *  @class BloodPressureViewController
 *
 *  @discussion Class to handle the user interactions and UI updates with blood pressure service
 *
 */
@interface BloodPressureViewController ()
{
    BPModel *mBPModel;
    BOOL isCharcteristicDiscovered; // Variable to determine whether the characteristic is successfully discovered
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bloodPressureImageViewHeightConstraint;

/* Data fields  */
@property (weak, nonatomic) IBOutlet UILabel *systolicPressureValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *diastolicPressureValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *systolicPressureUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *diastolicPressureUnitLabel;


@end

@implementation BloodPressureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initializeView];
    
    // Initialize the model for blood pressure service
    [self initBPModel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[super navBarTitleLabel] setText:BP];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [mBPModel stopUpdate];
}


/*!
 *  @method initializeView
 *
 *  @discussion Method to optimize the view for Ipad.
 *
 */

-(void) initializeView
{
    [_systolicPressureUnitLabel setHidden:YES];
    [_diastolicPressureUnitLabel setHidden:YES];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        _bloodPressureImageViewHeightConstraint.constant += DEFAULT_SIZE_NORMALISATION_CONSTANT_FOR_IPAD;
        [self.view layoutIfNeeded];
    }
}

/*!
 *  @method initBPModel
 *
 *  @discussion Method to Discover the specified characteristics of a service.
 *
 */

-(void) initBPModel
{
    if (!mBPModel)
    {
        mBPModel = [[BPModel alloc] init];
    }
    
    [mBPModel startDiscoverChar:^(BOOL success, NSError *error) {
        
        if (success)
        {
            isCharcteristicDiscovered = success;
        }
    }];
}

/*!
 *  @method startButtonClicked:
 *
 *  @discussion Handling the start and stop for receiving data from model
 *
 */

-(IBAction)startButtonClicked:(UIButton *)sender
{
    if(!sender.selected)
    {
        [_systolicPressureUnitLabel setHidden:NO];
        [_diastolicPressureUnitLabel setHidden:NO];

        // Update value only if the characteristic discovered successfully
        if (isCharcteristicDiscovered)
        {
            [self updateBPCharacteristic];
        }
        
        sender.selected = YES;
    }
    else
    {
        sender.selected = NO;
        [mBPModel stopUpdate];
    }
}
/*!
 *  @method updateBPCharacteristic
 *
 *  @discussion Method to Update UI when the characteristic’s value changes.
 *
 */

-(void) updateBPCharacteristic
{
    
    [mBPModel updateCharacteristicWithHandler:^(BOOL success, NSError *error) {
        
        if (success)
        {
            @synchronized(mBPModel){
               
                // Updating data fields
                _systolicPressureValueLabel.text = [NSString stringWithFormat:@"%0.2f",mBPModel.systolicPressureValue];
                _diastolicPressureValueLabel.text = [NSString stringWithFormat:@"%0.2f",mBPModel.diastolicPressureValue];
            }
        }
    }];
}



@end
