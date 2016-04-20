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

#import "BatteryServiceView.h"

#define BATTERY_VIEW_NIB_NAME  @"BatteryServiceView"

/*!
 *  @class BatteryServiceView
 *
 *  @discussion Class to initiate battery view and handle UI updates
 *
 */

@interface BatteryServiceView ()
{
    float percentViewRefHeight;
}

@property (weak, nonatomic) IBOutlet UIView *batteryPercentageView; // View for animating with battery level
@property (weak, nonatomic) IBOutlet UILabel *batteryPercentageValueLabel; // Datafield for battery level
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *batteryPercentageViewHeightConstraint;



@end



@implementation BatteryServiceView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame
{
    // View initialization
    self = [super initWithFrame:frame];
    if (self) {
        self = [[[NSBundle mainBundle] loadNibNamed:BATTERY_VIEW_NIB_NAME owner:self options:nil] objectAtIndex:0];
        self.frame = frame;
        percentViewRefHeight = _batteryPercentageView.frame.size.height; // store the initial view height
        [self layoutIfNeeded];
    }
    return self;
}

/*!
 *  @method animateBatteryPercentageValueTo: withDuration:
 *
 *  @discussion Method to change the UI with the battery percentage value
 *
 */

-(void) animateBatteryPercentageValueTo:(int)percentageValue withDuration:(float)duration
{
    // Calculate the view height with the current battery level value
    float heightValue = (percentViewRefHeight/100.0) * percentageValue;
    
    // View animation
    [UIView animateWithDuration:duration animations:^{
        _batteryPercentageViewHeightConstraint.constant = heightValue;
        [_batteryPercentageView layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        // The call back is ignored
        
    }];
    
    _batteryPercentageValueLabel.text = [NSString stringWithFormat:@"%d%%",percentageValue];
}


@end
