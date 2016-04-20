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

#import "HeartRateMesurementVC.h"
#import "HRMModel.h"
#import "MyLineChart.h"
#import "LoggerHandler.h"
#import "Utilities.h"



/*!
 *  @class HeartRateMesurementVC
 *
 *  @discussion Class to upadate UI and user interactions for heart rate measurement service
 *
 */
@interface HeartRateMesurementVC ()<lineChartDelegate>
{
    HRMModel *mHrmModel;
    
    MyLineChart *myChart;
    NSMutableArray *hrmDataArray;
    NSMutableArray *timeDataArray;
    KLCPopup* kPopup;
    NSDate *startTime;
    NSTimeInterval previousTimeInterval;
    float xAxisTimeInterval, heartImageHeight, heartImageWidth;
}

/* Data fields */
@property (weak, nonatomic) IBOutlet UILabel *heartRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *expendedEnergyLabel;
@property (weak, nonatomic) IBOutlet UILabel *RRIntervalLabel;
@property (weak, nonatomic) IBOutlet UIImageView *heartImageView;
@property (weak, nonatomic) IBOutlet UILabel *sensorLocationLabel;
@property (weak, nonatomic) IBOutlet UILabel *energyExpandedUnitLabel;
/* Constraint outlets to handle the images */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heartImageHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heartImageWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *flameImageHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ecgGraphImageHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sensorLocLabelCenterYConstraint;

@end

@implementation HeartRateMesurementVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initializeView];
    
    // Start the heart image animation when the user enters the screen
    [self animateHeartImage];
    
    // Initialize model
    [self initHrmModel];
    
    hrmDataArray = [NSMutableArray array];
    timeDataArray = [NSMutableArray array];
    
    // Initialize time
    startTime = [NSDate date];
    
    previousTimeInterval = 0;
    xAxisTimeInterval = 1.0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[super navBarTitleLabel] setText:HEART_RATE_MEASUREMENT];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];

    if (IS_IPHONE_4_OR_LESS) {
        _sensorLocLabelCenterYConstraint.constant = 25;
        [self.view layoutIfNeeded];
    }
}


-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];

    if (![self.navigationController.viewControllers containsObject:self])
    {
        [mHrmModel stopUpdate]; //   Stop receiving characteristic value when the user exits the screen
        [kPopup dismiss:YES];
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
 *  @method initHrmModel
 *
 *  @discussion Method to Discover the specified characteristics of a service.
 *
 */

-(void)initHrmModel
{
    mHrmModel = [[HRMModel alloc] init];
    [mHrmModel startDiscoverChar:^(BOOL success, NSError *error) {
        
        if(success)
        {
            // Get the characteristic value if the characteristic is found successfully
            [self startUpdateChar];
        }
    }];
}


/*!
 *  @method startUpdateChar
 *
 *  @discussion Method to get the value of specified characteristic.
 *
 */

-(void)startUpdateChar
{
    [mHrmModel updateCharacteristicWithHandler:^(BOOL success, NSError *error)
    {
        @synchronized(mHrmModel){
            // Handle the characteristic values if successfully received
            [self updateHRM];
        }
    }];
}

/*!
 *  @method initializeView
 *
 *  @discussion Method to optimize the UI for Ipad screens.
 *
 */

-(void) initializeView
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        // Change the image size
        _flameImageHeightConstraint.constant +=  DEFAULT_SIZE_NORMALISATION_CONSTANT_FOR_IPAD;
        _ecgGraphImageHeightConstraint.constant += DEFAULT_SIZE_NORMALISATION_CONSTANT_FOR_IPAD ;
        _heartImageHeightConstraint.constant += DEFAULT_SIZE_NORMALISATION_CONSTANT_FOR_IPAD;
        _heartImageWidthConstraint.constant += DEFAULT_SIZE_NORMALISATION_CONSTANT_FOR_IPAD;
        
        [self.view layoutIfNeeded];
    }
    
    heartImageHeight = _heartImageHeightConstraint.constant;
    heartImageWidth = _heartImageWidthConstraint.constant;
}

/*!
 *  @method animateHeartImage
 *
 *  @discussion Method to handle the animation of heart image.
 *
 */

-(void) animateHeartImage
{
    [UIView animateWithDuration:2
                          delay:0.0
                        options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat
                     animations:^{
        _heartImageHeightConstraint.constant = _heartImageView.frame.size.height/2.6;
        _heartImageWidthConstraint.constant =  _heartImageView.frame.size.width/2.6;
        [_heartImageView layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        
    }];
}


/*!
 *  @method updateHRM
 *
 *  @discussion Method to Update UI related to characteristic
 *
 */

-(void)updateHRM
{
    // Update datafields
    _heartRateLabel.text = [NSString stringWithFormat:@"%ld",(long)mHrmModel.bpmValue];
    _sensorLocationLabel.text = mHrmModel.sensorLocation;
    _RRIntervalLabel.text = mHrmModel.RR_Interval;
    _expendedEnergyLabel.text = mHrmModel.EnergyExpended;
    
    if ([mHrmModel.EnergyExpended isEqual:@"Nil"]) {
        _energyExpandedUnitLabel.text = @"";
    }else{
        _energyExpandedUnitLabel.text = @"  kcal";
    }
    
    // Handle the characteristic values to update graph
    if(mHrmModel.bpmValue)
    {
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
        [hrmDataArray addObject:@(mHrmModel.bpmValue)];
        
        if(myChart && kPopup.isShowing)
        {
            [self checkGraphPointsCount];
            [myChart updateLineGraph:timeDataArray Y:hrmDataArray ];
            [myChart setXaxisScaleWithValue:nearbyintf(xAxisTimeInterval)];
        }
        previousTimeInterval = timeInterval;
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
 *  @method showGraphPopUp:
 *
 *  @discussion Method to show Graph .
 *
 */

-(IBAction)showGraphPopUp:(id)sender
{
    if(myChart)
        myChart = nil;
    myChart =[[MyLineChart alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/2.0)];
    myChart.graphTitleLabel.text = HEART_RATE_GRAPH_HEADER;
    [myChart addXLabel:TIME yLabel:HEART_RATE_YLABEL];
    myChart.delegate = self;
    
    if([timeDataArray count])
    {
        [self checkGraphPointsCount];
        [myChart updateLineGraph:timeDataArray Y:hrmDataArray ];
        
        KLCPopupLayout layout = KLCPopupLayoutMake(KLCPopupHorizontalLayoutCenter,
                                                   KLCPopupVerticalLayoutBottom);
        
        if(kPopup)
            kPopup =  nil;
        kPopup = [KLCPopup popupWithContentView:myChart
                                       showType:KLCPopupShowTypeBounceIn
                                    dismissType:KLCPopupDismissTypeBounceOut
                                       maskType:KLCPopupMaskTypeDimmed
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
    
    if (hrmDataArray.count > MAX_GRAPH_POINTS) {
        hrmDataArray = [[hrmDataArray subarrayWithRange:NSMakeRange( hrmDataArray.count - MAX_GRAPH_POINTS,MAX_GRAPH_POINTS)] mutableCopy];
    }
}

/*!
 *  @method applicationDidEnterForeground:
 *
 *  @discussion Method to handle the heart image animation while application enter in foreground.
 *
 */
-(void)applicationDidEnterForeground:(NSNotification *) notification
{
    [self animateHeartImage];
}


/*!
 *  @method applicationDidEnterBackground:
 *
 *  @discussion Method to handle heart image animation while the app goes to background
 *
 */
-(void)applicationDidEnterBackground:(NSNotification *) notification{
    
    _heartImageHeightConstraint.constant = heartImageHeight;
    _heartImageWidthConstraint.constant = heartImageWidth;
    
    [_heartImageView.layer removeAllAnimations];
    [self.view layoutIfNeeded];
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
