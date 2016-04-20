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
#import "CyclingSpeedAndCadenceVC.h"
#import "CSCModel.h"
#import "Utilities.h"
#import "MyLineChart.h"
#import "UIView+Toast.h"

#define WEIGHT_TEXTFIELD_TAG        100
#define WHEEL_RADIUS_TEXTFIELD_TAG  101


/*!
 *  @class CyclingSpeedAndCadenceVC
 *
 *  @discussion Class to handle the user interactions and UI updates for cycling speeed and cadence service 
 *
 */

@interface CyclingSpeedAndCadenceVC ()<UITextFieldDelegate, lineChartDelegate>
{
    CSCModel *mCSCModel;
    NSTimer *timeValueUpdationTimer;
    NSDate *startTime ;
    int timerValue;
    
    BOOL isCharDiscovered;    // Varieble to determine whether the required characteristic is found
    
    KLCPopup* kPopup;
    MyLineChart *myChart;
    BOOL isStartTimeSet;
    NSMutableArray *rpmDataArray;
    NSMutableArray *timeDataArray;
    
    NSTimeInterval previousTimeInterval;
    float xAxisTimeInterval;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;

/* UI Label datafields */

@property (weak, nonatomic) IBOutlet UILabel *wheelRPMLabel;
@property (weak, nonatomic) IBOutlet UILabel *wheelRPMUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *coveredDistanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *coveredDistanceUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *burnedCaloriesLabel;
@property (weak, nonatomic) IBOutlet UILabel *burnedCaloriesUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) IBOutlet UITextField *userWeightTextField;
@property (weak, nonatomic) IBOutlet UITextField *wheelRadiusTextField;
@property (weak, nonatomic) IBOutlet UIButton *startButton;

@end

@implementation CyclingSpeedAndCadenceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    rpmDataArray = [NSMutableArray array];
    timeDataArray = [NSMutableArray array];
    [self initializeView];
    
    // Initialize CSC model
    [self initCSCModel];
    [self addDoneButton];
    
    previousTimeInterval = 0;
    xAxisTimeInterval = 1.0;
    timerValue = 0;
    isStartTimeSet = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[super navBarTitleLabel] setText:CSC];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:self];
    
    if (![self.navigationController.viewControllers containsObject:self])
    {
        [mCSCModel stopUpdate];    // stop receiving characteristic value when the user exits the screen
        [kPopup dismiss:YES];      // Remove graph pop up
    }
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


/*!
 *  @method initializeView
 *
 *  @discussion Method to change image size for Ipad.
 *
 */

-(void) initializeView
{
    if (IS_IPAD)
    {
        _contentViewHeightConstraint.constant = self.view.frame.size.height - (NAV_BAR_HEIGHT + STATUS_BAR_HEIGHT)
        ;
        [self.view layoutIfNeeded];
    }
    _coveredDistanceLabel.text = @"";
    _coveredDistanceUnitLabel.text = @"";
    [_burnedCaloriesUnitLabel setHidden:YES];
    [_wheelRPMUnitLabel setHidden:YES];
}


/*!
 *  @method initCSCModel
 *
 *  @discussion Method to Discovers the specified characteristics of a service.
 *
 */

-(void) initCSCModel
{
    if (!mCSCModel)
    {
        mCSCModel = [[CSCModel alloc] init];
    }
    
    [mCSCModel startDiscoverChar:^(BOOL success, NSError *error) {
        if (success) {
            // Set flag if the required characteristic is found
            isCharDiscovered = success;
        }
    }];
}

/*!
 *  @method startUpdateCharacteristic
 *
 *  @discussion Method to assign completion handler to get call back once the block has completed execution.
 *
 */

-(void) startUpdateCharacteristic
{
    [mCSCModel updateCharacteristicWithHandler:^(BOOL success, NSError *error)
    {
        // checking whether timer used for ellapsed time calculation exist
        if (success && timeValueUpdationTimer)
        {
            [self updateUI];
        }
    }];
}


/*!
 *  @method updateUI
 *
 *  @discussion Method to Update UI when the characteristic’s value changes.
 *
 */

-(void) updateUI
{
    @synchronized(mCSCModel){
        
        // Calculate and display distance, RPM and calories burnt
        [self findDistance];
        [self updateRPM];
    }
}


/*!
 *  @method startCountingTime:
 *
 *  @discussion Method to handle start and stop receiving characteristic value
 *
 */

- (IBAction)startCountingTime:(UIButton *)sender
{
    if (!sender.selected)
    {
        NSString *toastMessage = @"";
        
        // Checking weight textfield
        
        if([_userWeightTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0){
            toastMessage = LOCALIZEDSTRING(@"emptyWeightFieldWarning");
        }else if ([_userWeightTextField.text floatValue] < 1){
            toastMessage = LOCALIZEDSTRING(@"minWeightWarning");
        }else if([_userWeightTextField.text floatValue] > 200){
            toastMessage = LOCALIZEDSTRING(@"maxWeightWarning");
        }
        
        
        if (![toastMessage isEqualToString:@""]) {
            toastMessage = [toastMessage stringByAppendingString:@"\n"];
        }
        
        // Checking wheel radius textfield
        
        if ([_wheelRadiusTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
            toastMessage = [toastMessage stringByAppendingString:LOCALIZEDSTRING(@"emptyRadiusFieldWarning")];
        }else if ([_wheelRadiusTextField.text integerValue] < 300){
            toastMessage = [toastMessage stringByAppendingString:LOCALIZEDSTRING(@"minRadiusWarning")];
        }else if ([_wheelRadiusTextField.text integerValue] > 725){
            toastMessage = [toastMessage stringByAppendingString:LOCALIZEDSTRING(@"maxRadiusWarning")];
        }
        
        if (![toastMessage isEqualToString:@""]) {
            [self.view makeToast:toastMessage];
        }
        
        [_burnedCaloriesUnitLabel setHidden:NO];
        [_wheelRPMUnitLabel setHidden:NO];

        if(isCharDiscovered)
        {
            int wheelRadius = [_wheelRadiusTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length>0?[_wheelRadiusTextField.text intValue]:0;
            mCSCModel.wheelRadius = wheelRadius;
            
            [self startUpdateCharacteristic];

            // Remove keyboard
            if ([_userWeightTextField isFirstResponder]) {
                [_userWeightTextField resignFirstResponder];
            }
            
            if ([_wheelRadiusTextField isFirstResponder]) {
                [_wheelRadiusTextField resignFirstResponder];
            }
            
            if (!isStartTimeSet)
            {
                startTime = [NSDate date];
                isStartTimeSet = YES;
            }
            timerValue = 0;
            timeValueUpdationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimeLabel) userInfo:nil repeats:YES];
            sender.selected = YES;
        }

    }
    else
    {
        if (timeValueUpdationTimer)
        {
            [timeValueUpdationTimer invalidate];
        }
        sender.selected = NO;
        [mCSCModel stopUpdate];
    }
}



/*!
 *  @method updateTimeLabel
 *
 *  @discussion Method to show the ellapsed time
 *
 */
-(void)updateTimeLabel
{
    timerValue++;
    _timeLabel.text =  [Utilities timeInFormat:timerValue];
    
    // Calculate and update Calories burnt
    
    float userWeight = [[_userWeightTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0 ? [_userWeightTextField.text floatValue] : 0.0f;
    float burntCaloriesAmount = 0;
    if (userWeight >0)
    {
        float time = (float)(timerValue / 60.0);
        burntCaloriesAmount = (time * userWeight * 8.0)/ 1000;
    }
    _burnedCaloriesLabel.text = [NSString stringWithFormat:@"%0.4f",burntCaloriesAmount];
}


/*!
 *  @method findDistance
 *
 *  @discussion Method to show the distance covered
 *
 */
-(void)findDistance
{
    // Check the unit in which the distance should be shown
    if(mCSCModel.coveredDistance < 1000)
    {
        _coveredDistanceLabel.text = [NSString stringWithFormat:@"%0.2f",mCSCModel.coveredDistance];
        _coveredDistanceUnitLabel.text = @"m";
    }
    else
    {
        _coveredDistanceLabel.text = [NSString stringWithFormat:@"%0.2f",[Utilities meterToKM:mCSCModel.coveredDistance]];
        _coveredDistanceUnitLabel.text = @"km";
    }
}


/*!
 *  @method updateRPM
 *
 *  @discussion Method to update wheel RPM
 *
 */
-(void)updateRPM
{
    if (mCSCModel.cadence > 0)
    {
        _wheelRPMLabel.text = [NSString stringWithFormat:@"%d",mCSCModel.cadence];
        // Handle graph
        if(mCSCModel.cadence == INFINITY || mCSCModel.cadence == NAN)
        {
        }
        else
        {
            [rpmDataArray addObject:@(mCSCModel.cadence)];
            
            NSTimeInterval timeInterval = fabs([startTime timeIntervalSinceNow]);
            
            if (previousTimeInterval == 0)
            {
                previousTimeInterval = timeInterval;
            }
            
            if (timeInterval > previousTimeInterval)
            {
                xAxisTimeInterval = timeInterval - previousTimeInterval;
            }
            
            [timeDataArray addObject:@(timeInterval)];
            
            if(myChart && kPopup.isShowing)
            {
                [self checkGraphPointsCount];
                [myChart updateLineGraph:timeDataArray Y:rpmDataArray];
                [myChart setXaxisScaleWithValue:nearbyintf(xAxisTimeInterval)];
            }
            previousTimeInterval = timeInterval;
        }
    }
}


#pragma mark - UITextfield Delegate Methods


-(BOOL) textFieldShouldBeginEditing:(UITextField *)textField
{
    if (_startButton.selected)
    {
        return NO;
    }
    return YES;
}


-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.tag == WEIGHT_TEXTFIELD_TAG) {
        
        if ([string isEqualToString:@""]) {
            return YES;
        }else if ([string rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location != NSNotFound){
            
            if ([string isEqualToString:@"." ] && [textField.text rangeOfString:@"."].length == 0 && textField.text.length <= 3) {
                return YES;
            }
            return NO;
            
        }else{
            
            if ([textField.text rangeOfString:@"."].length > 0 && ![textField.text hasSuffix:@"."]) {
                return NO;
            }
            
            if ([textField.text rangeOfString:@"."].length == 0 && textField.text.length == 3) {
                return NO;
            }
        }
    }
    else if (textField.tag == WHEEL_RADIUS_TEXTFIELD_TAG)
    {
        if ([string isEqualToString:@""]) {
            return YES;
        }else if ([string rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location != NSNotFound){
            return NO;
        }else if (textField.text.length >= 3){
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Utility Methods

/*!
 *  @method showGraphPopUp:
 *
 *  @discussion Method to show Graph .
 *
 */

-(IBAction)showGraphPopUp:(id)sender
{
    if (myChart) {
        myChart = nil;
    }
    myChart =[[MyLineChart alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/2.0)];
    myChart.graphTitleLabel.text = CYCLING_GRAPH_HEADER;
    [myChart addXLabel:TIME yLabel:CYCLING_GRAPH_YLABEL];
    myChart.delegate = self;
    
    if([timeDataArray count])
    {
        [self checkGraphPointsCount];
        [myChart updateLineGraph:timeDataArray Y:rpmDataArray];
        
        KLCPopupLayout layout = KLCPopupLayoutMake(KLCPopupHorizontalLayoutCenter,
                                                   KLCPopupVerticalLayoutBottom);
        
        kPopup = [KLCPopup popupWithContentView:myChart
                                       showType:KLCPopupShowTypeBounceIn
                                    dismissType:KLCPopupDismissTypeBounceOut
                                       maskType:KLCPopupMaskTypeClear
                       dismissOnBackgroundTouch:YES
                          dismissOnContentTouch:NO];
        [kPopup showWithLayout:layout];
    }
    else
        [Utilities alert:APP_NAME Message:LOCALIZEDSTRING(@"graphDataNotAvailableAlert")];
    
}

/*!
 *  @method checkGraphPointsCount
 *
 *  @discussion Method to check the graph plot points
 *
 */
-(void) checkGraphPointsCount{
    
    if (timeDataArray.count > MAX_GRAPH_POINTS) {
        timeDataArray = [[timeDataArray subarrayWithRange:NSMakeRange(timeDataArray.count - MAX_GRAPH_POINTS,MAX_GRAPH_POINTS)] mutableCopy];
        myChart.chartView.setXmin = YES;
    }else{
        myChart.chartView.setXmin = NO;
    }
    
    if (rpmDataArray.count > MAX_GRAPH_POINTS) {
        rpmDataArray = [[rpmDataArray subarrayWithRange:NSMakeRange(rpmDataArray.count - MAX_GRAPH_POINTS,MAX_GRAPH_POINTS)] mutableCopy];
    }
}

/*!
 *  @method shareScreen:
 *
 *  @discussion Method to share the screen
 *
 */

-(void)shareScreen:(id)sender
{
    UIImage *screenShot = [Utilities captureScreenShot];
    [kPopup dismiss:YES];
    
    CGRect rect = [(UIButton *)sender frame];
    
    CGRect newRect = CGRectMake(rect.origin.x, rect.origin.y + (self.view.frame.size.height/2), rect.size.width, rect.size.height);
    [self showActivityPopover:[self saveImage:screenShot] Rect:newRect excludedActivities:nil];
}


/*!
 *  @method addDoneButton:
 *
 *  @discussion Method to add a done button on top of the keyboard when displayed
 *
 */

- (void)addDoneButton {
    UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];
    [keyboardToolbar sizeToFit];
    UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil action:nil];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self action:@selector(doneButtonPressed)];
    keyboardToolbar.items = @[flexBarButton, doneBarButton];
    _userWeightTextField.inputAccessoryView = keyboardToolbar;
    _wheelRadiusTextField.inputAccessoryView = keyboardToolbar;
}

/*!
 *  @method addDoneButton:
 *
 *  @discussion Method to get notified when the custom done button on top of keyboard is tapped
 *
 */

- (void)doneButtonPressed {
    [self.view endEditing:YES];
}

/*!
 *  @method deviceOrientationChanged:
 *
 *  @discussion Method to handle the graph frame with interface orienation
 *
 */
-(void)deviceOrientationChanged:(NSNotification *)notification
{
    if (IS_IPAD && kPopup.isShowing && [UIDevice currentDevice].orientation != UIDeviceOrientationFaceUp)
    {
        [kPopup dismiss:NO];
        [self showGraphPopUp:nil];
    }
}

@end
