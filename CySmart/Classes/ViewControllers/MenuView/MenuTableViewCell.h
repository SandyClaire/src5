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
#import <UIKit/UIKit.h>
/*!
 *  @class MenuTableViewCell
 *
 *  @discussion Class to handle the cell in menu list view
 *
 */
@interface MenuTableViewCell : UITableViewCell

/*!
 *  @property menuItemImageview
 *
 *  @discussion View to set images for menu items
 *
 */
@property (weak, nonatomic) IBOutlet UIImageView *menuItemImageview;

/*!
*  @property menuItemLabel
*
*  @discussion Datafield to display the menu item name
*
*/

@property (weak, nonatomic) IBOutlet UILabel *menuItemLabel;

/*!
 *  @property menuItemImageViewLeadingConstraint
 *
 *  @discussion Leading constraint of the imageview
 *
 */

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *menuItemImageViewLeadingConstraint;

@end
