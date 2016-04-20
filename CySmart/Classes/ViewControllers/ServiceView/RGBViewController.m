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

#import "RGBViewController.h"
#import "RGBModel.h"
#import "Constants.h"


/*!
 *  @class RGBViewController
 *
 *  @discussion Class to handle user interactions and UI updation for RGB service
 *
 */
@interface RGBViewController ()
{
    RGBModel *rgbModel;
}

@property (weak, nonatomic) IBOutlet UIView *pickerContainer;
@property (weak, nonatomic) IBOutlet UIImageView *gamutImage;
@property (weak, nonatomic) IBOutlet UIImageView *thumbImage;
@property (weak, nonatomic) IBOutlet UISlider *intensitySlider;
@property (weak, nonatomic) IBOutlet UIView *colorValueContainerView;
@property (weak, nonatomic) IBOutlet UIView * ColorSelectionView;

/* Datafields */
@property (weak, nonatomic) IBOutlet UILabel *currentColorLabel;
@property (weak, nonatomic) IBOutlet UILabel *redColorLabel;
@property (weak, nonatomic) IBOutlet UILabel *greenColorLabel;
@property (weak, nonatomic) IBOutlet UILabel *blueColorLabel;
@property (weak, nonatomic) IBOutlet UILabel *intensityLabel;

/*Layout constraints for dynamically updating UI layouts*/
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * colorSelectionViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * colorSelectionViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * valuesDisplayViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint * valuesDisplayViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *colourSelectionViewTopDistanceConstraint;

- (IBAction)intensityChanged:(id)sender;

@end

@implementation RGBViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initView];
    [self startUpdate];
    
    // Adding the tap gesture recognizer with uislider to get the tap
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderTapped:)] ;
    [_intensitySlider addGestureRecognizer:tapRecognizer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[self navBarTitleLabel] setText:RGB_LED];
    
    [self deviceOrientationChanged:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    
    if (![self.navigationController.viewControllers containsObject:self])
    {
        //   Stop receiving characteristic value when the user exits the screen
        [rgbModel stopUpdate];
    }
}

/*!
 *  @method initView
 *
 *  @discussion Method to init the view.
 *
 */

- (void)initView
{
    _colourSelectionViewTopDistanceConstraint.constant = _colourSelectionViewTopDistanceConstraint.constant + NAV_BAR_HEIGHT;
    
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        _valuesDisplayViewHeightConstraint.constant = self.view.frame.size.height - NAV_BAR_HEIGHT - STATUS_BAR_HEIGHT;
        _colorSelectionViewHeightConstraint.constant = self.view.frame.size.height - NAV_BAR_HEIGHT - STATUS_BAR_HEIGHT;
        _colorSelectionViewWidthConstraint.constant = self.view.frame.size.width * 0.6;
        _valuesDisplayViewWidthConstraint.constant = (self.view.frame.size.width * 0.4) - NAV_BAR_HEIGHT - STATUS_BAR_HEIGHT;
        [self.view layoutIfNeeded];
        [self.view layoutSubviews];
        
    }else{
        if (self.view.frame.size.height * 0.6 > 300){
            _colorSelectionViewHeightConstraint.constant = self.view.frame.size.height * 0.5;
            [self.view layoutIfNeeded];
            _valuesDisplayViewHeightConstraint.constant = self.view.frame.size.height - CGRectGetMaxY(_ColorSelectionView.frame) - 60;
        }else{
            _colorSelectionViewHeightConstraint.constant = 260.0f;
            _valuesDisplayViewHeightConstraint.constant = self.view.frame.size.height - 260.0f - STATUS_BAR_HEIGHT - NAV_BAR_HEIGHT;
        }
        _colorSelectionViewWidthConstraint.constant = self.view.frame.size.width;
        _valuesDisplayViewWidthConstraint.constant = self.view.frame.size.width;
        [self.view layoutIfNeeded];
    }
}

/*!
 *  @method startUpdate
 *
 *  @discussion Method to get value from specified characteristic.
 *
 */
-(void)startUpdate
{
    rgbModel = [[RGBModel alloc] init];
    [rgbModel updateCharacteristicWithHandler:^(BOOL success, NSError *error)
     {
         // Getting and setting the initial colour when the user enters the screen
         [self colorOfPoint:_thumbImage.center];
         [self updateRGBValues];
     }];
}

/*!
 *  @method updateRGBValues
 *
 *  @discussion Method to update the colour and intensity in data fields.
 *
 */
-(void)updateRGBValues
{
    // Upadating datafields
    _redColorLabel.text = [self updateColorString:_redColorLabel.text To:rgbModel.redColor];
    _greenColorLabel.text = [self updateColorString:_greenColorLabel.text To:rgbModel.greenColor];
    _blueColorLabel.text = [self updateColorString:_blueColorLabel.text To:rgbModel.blueColor];
    _intensityLabel.text = [self updateColorString:_intensityLabel.text To:rgbModel.intensity];
    
    _currentColorLabel.backgroundColor = [UIColor colorWithRed:rgbModel.redColor/255.0 green:rgbModel.greenColor/255.0 blue:rgbModel.blueColor/255.0 alpha:1];
}

/*!
 *  @method updateColorString:To:
 *
 *  @discussion Method that returns the hexValue as string
 *
 */

-(NSString *)updateColorString:(NSString *)string To:(NSInteger)latestValue
{
    return [NSString stringWithFormat:@"0x%02lx",(long)latestValue];
}

/*!
 *  @method intensityChanged:
 *
 *  @discussion Method to handle the inensity change
 *
 */

- (IBAction)intensityChanged:(id)sender
{
    // Write the intensity values to the device
    [rgbModel writeColor:rgbModel.redColor BColor:rgbModel.blueColor GColor:rgbModel.greenColor Intensity:_intensitySlider.value With:^(BOOL success, NSError *error) {
        [self updateRGBValues];
    }];
}

#pragma mark - Device orientation notification

/*!
 *  @method deviceOrientationChanged:
 *
 *  @discussion Method to handle the orientation change
 *
 */
-(void) deviceOrientationChanged:(NSNotification *) notification
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            _valuesDisplayViewHeightConstraint.constant = self.view.frame.size.height - NAV_BAR_HEIGHT - STATUS_BAR_HEIGHT;
            _colorSelectionViewHeightConstraint.constant = self.view.frame.size.height - NAV_BAR_HEIGHT - STATUS_BAR_HEIGHT;
            _colorSelectionViewWidthConstraint.constant = self.view.frame.size.width * 0.6;
            _valuesDisplayViewWidthConstraint.constant = (self.view.frame.size.width * 0.4) - NAV_BAR_HEIGHT - STATUS_BAR_HEIGHT;
            [self.view layoutIfNeeded];
        }else{
            _colorSelectionViewHeightConstraint.constant = self.view.frame.size.height * 0.5;
            [self.view layoutIfNeeded];
            
            _valuesDisplayViewHeightConstraint.constant = self.view.frame.size.height - CGRectGetMaxY(_ColorSelectionView.frame) - 60;
            _colorSelectionViewWidthConstraint.constant = self.view.frame.size.width;
            _valuesDisplayViewWidthConstraint.constant = self.view.frame.size.width;
            [self.view layoutIfNeeded];
        }
        
        // Getting and setting the initial colour when the user rotates the screen
        [self colorOfPoint:_thumbImage.center];
        [self updateRGBValues];
    }
}


#pragma mark - tap in slider

/*!
 *  @method sliderTapped:
 *
 *  @discussion Method to handle the the tap on slider
 *
 */

-(void) sliderTapped:(UIGestureRecognizer *)gestureRecognizer
{
    if (_intensitySlider.highlighted)
        return; // tap on thumb, let slider deal with it
    CGPoint point = [gestureRecognizer locationInView: _intensitySlider];
    CGFloat percentage = point.x / _intensitySlider.bounds.size.width;
    CGFloat delta = percentage * (_intensitySlider.maximumValue - _intensitySlider.minimumValue);
    CGFloat value = _intensitySlider.minimumValue + delta;
    [_intensitySlider setValue:value animated:YES];
    
    // Write the intensity values to the device
    [rgbModel writeColor:rgbModel.redColor BColor:rgbModel.blueColor GColor:rgbModel.greenColor Intensity:_intensitySlider.value With:^(BOOL success, NSError *error) {
        [self updateRGBValues];
    }];
}


#pragma mark - Touch Methods

/* Methods to handle the touch events */
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint tappedPt = [[touches anyObject] locationInView:_pickerContainer];
    [self colorOfPoint:tappedPt]; // Get colour at the point where the touch began
}


- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    CGPoint tappedPt = [[touches anyObject] locationInView:_pickerContainer];
    [self colorOfPoint:tappedPt]; // Get colour at the point where the touch ended
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    CGPoint tappedPt = [[touches anyObject] locationInView:_pickerContainer];
    [self colorOfPoint:tappedPt]; // Get colour at the current point
}

/*!
 *  @method colorOfPoint:
 *
 *  @discussion Method that returns the colour at a particular point
 *
 */

-(UIColor *) colorOfPoint:(CGPoint)point
{
    _thumbImage.hidden = YES;
    unsigned char pixel[4] = {0};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixel,
                                                 1, 1, 8, 4, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    
    CGContextTranslateCTM(context, -point.x, -point.y);
    
    [_pickerContainer.layer renderInContext:context];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    UIColor *color = [UIColor colorWithRed:pixel[0]/255.0
                                     green:pixel[1]/255.0
                                      blue:pixel[2]/255.0
                                     alpha:pixel[3]/255.0];
    
    _thumbImage.hidden = NO;
    
    // Checking the selected colour reside inside the colour gamut
    if(pixel[3] <= 0 || (pixel[0] <= 0 && pixel[1] <= 0 && pixel[2] <= 0 ))
    {
        
    }
    else
    {
        // Writing the colour values to the peripheral
        [rgbModel writeColor:pixel[0] BColor:pixel[2] GColor:pixel[1] Intensity:_intensitySlider.value With:^(BOOL success, NSError *error)
         {
             if (success)
             {
                 [self updateRGBValues];
             }
         }];
        _thumbImage.center = point ;
        [_currentColorLabel setBackgroundColor:color];   //showing the current selected colour in the screen
    }
    return color;
}




@end
