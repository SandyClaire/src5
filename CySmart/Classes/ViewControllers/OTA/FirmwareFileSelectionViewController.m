/*
 * Copyright Cypress Semiconductor Corporation, 2015 All rights reserved.
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

#import <QuartzCore/QuartzCore.h>
#import "FirmwareFileSelectionViewController.h"
#import "Utilities.h"

#define BACK_BUTTON_IMAGE                           @"backButton"

#define CHECKBOX_BUTTON_TAG     15
#define FILENAME_LABEL_TAG      25
#define ACTIVITY_INDICATOR_TAG  35


/*!
 *  @class FirmwareFileSelectionViewController
 *
 *  @discussion Class to handle the firmware file selection
 *
 */

@interface FirmwareFileSelectionViewController () <UITableViewDataSource, UITableViewDelegate>
{
    IBOutlet UITableView * fileListTable;
    IBOutlet UILabel * headerLabel;
    IBOutlet UIButton * upgradeButton;
    NSMutableArray * selectedFirmwareFilesArray;
    NSArray * firmwareFilesListArray;
    BOOL isFileSearchFinished, isStackFileSelected;
}
@end

@implementation FirmwareFileSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initiateView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[super navBarTitleLabel] setText:FIRMWARE_UPGRADE];
    
    isFileSearchFinished = NO;
    isStackFileSelected = NO;
    selectedFirmwareFilesArray = [NSMutableArray new];
    [self findFilesInDocumentsFolderWithFinishBlock:^(NSArray * fileListArray) {
        firmwareFilesListArray = [[NSArray alloc] initWithArray:fileListArray];
        isFileSearchFinished = YES;
        [fileListTable reloadData];
    }];
    UIBarButtonItem * backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:BACK_BUTTON_IMAGE] landscapeImagePhone:[UIImage imageNamed:BACK_BUTTON_IMAGE] style:UIBarButtonItemStyleDone target:self action:@selector(backButtonAction)];
    self.navigationItem.leftBarButtonItem = backButton;
    self.navigationItem.leftBarButtonItem.imageInsets = UIEdgeInsetsMake(0, -8, 0, 0);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*!
 *  @method initiateView
 *
 *  @discussion Method - Setting the view initially or resets it into inital mode when required.
 *
 */
- (void)initiateView
{
    fileListTable.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    if (_selectedUpgradeMode == app_stack_separate) {
        headerLabel.text = LOCALIZEDSTRING(@"selectStackfile");
        [upgradeButton setTitle:UPGRADE_BTN_TITLE_FOR_SEPERATE_SELECTION forState:UIControlStateNormal];
    }else{
        headerLabel.text = LOCALIZEDSTRING(@"selectFirmwareFile");
        [upgradeButton setTitle:UPGRADE_BTN_TITLE_DEFAULT forState:UIControlStateNormal];
    }
}

#pragma mark - Button Events

/*!
 *  @method upgradeBtnTouched
 *
 *  @discussion Method - Button action method for sending selected files to OTAHomeVC
 *
 */
- (IBAction)upgradeBtnTouched:(UIButton *)sender
{
    if (_selectedUpgradeMode == app_stack_separate) {
        if ([upgradeButton.titleLabel.text isEqualToString:UPGRADE_BTN_TITLE_FOR_SEPERATE_SELECTION]) {
            if (selectedFirmwareFilesArray.count == 0) {
                [Utilities alert:APP_NAME Message:LOCALIZEDSTRING(@"selectStackFileToProceed")];
            }else{
                isStackFileSelected = YES;
                headerLabel.text = LOCALIZEDSTRING(@"selectApplicationFile");
                [upgradeButton setTitle:UPGRADE_BTN_TITLE_DEFAULT forState:UIControlStateNormal];
                [fileListTable reloadData];
            }
        }else{
            if (selectedFirmwareFilesArray.count < 2) {
                [Utilities alert:APP_NAME Message:LOCALIZEDSTRING(@"selectApplicationFileToProceed")];
            }else{
                [self.navigationController popViewControllerAnimated:YES];
                [self.delegate firmwareFilesSelected:selectedFirmwareFilesArray forUpgradeMode:_selectedUpgradeMode];
            }
        }
    }else{
        if (selectedFirmwareFilesArray.count == 0) {
            if (_selectedUpgradeMode == app_stack_combined)
            {
                [Utilities alert:APP_NAME Message:LOCALIZEDSTRING(@"selectSingleFileForUpgrade")];
            }
            else
                [Utilities alert:APP_NAME Message:LOCALIZEDSTRING(@"selectFileForApplicationUpgrade")];
        }else{
            [self.navigationController popViewControllerAnimated:YES];
            [self.delegate firmwareFilesSelected:selectedFirmwareFilesArray forUpgradeMode:_selectedUpgradeMode];
        }
    }
    
}

/*!
 *  @method backButtonAction
 *
 *  @discussion Method - Custom Nav bar back button action to handle multiple file selection scenario
 *
 */

- (void) backButtonAction
{
    if (_selectedUpgradeMode == app_stack_separate && [upgradeButton.titleLabel.text isEqualToString:UPGRADE_BTN_TITLE_DEFAULT]) {
        if (selectedFirmwareFilesArray.count > 1) {
            [selectedFirmwareFilesArray removeObjectAtIndex:1];
        }
        isStackFileSelected = NO;
        headerLabel.text = LOCALIZEDSTRING(@"selectStackfile");
        [upgradeButton setTitle:UPGRADE_BTN_TITLE_FOR_SEPERATE_SELECTION forState:UIControlStateNormal];
        [fileListTable reloadData];
    }else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Read .cyacd Files
/*!
 *  @method findFilesInDocumentsFolderWithFinishBlock
 *
 *  @discussion Method - Searches the document folder of app for .cyacd files and lists them in table
 *
 */
- (void)findFilesInDocumentsFolderWithFinishBlock:(void(^)(NSArray *))finish
{
    NSMutableArray * fileListArray = [NSMutableArray new];
    
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirPath = [documentPaths objectAtIndex:0];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:documentsDirPath error:nil];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pathExtension == 'cyacd'"];
    NSArray * fileNameArray = (NSMutableArray *)[dirContents filteredArrayUsingPredicate:predicate];
    
    for (NSString * fileName in fileNameArray) {
        NSMutableDictionary * firmwareFile = [NSMutableDictionary new];
        [firmwareFile setValue:fileName forKey:FILE_NAME];
        [firmwareFile setValue:documentsDirPath forKey:FILE_PATH];
        [fileListArray addObject:firmwareFile];
    }
    if (finish) {
        finish(fileListArray);
    }
}


#pragma mark - Table View Delegates

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"firmwareFileCell"];
    UIActivityIndicatorView * loadingIndicator = (UIActivityIndicatorView *)[cell.contentView viewWithTag:ACTIVITY_INDICATOR_TAG];
    UILabel * fileNameLbl = (UILabel *) [cell.contentView viewWithTag:FILENAME_LABEL_TAG];
    UIButton * checkBoxBtn = (UIButton *) [cell.contentView viewWithTag:CHECKBOX_BUTTON_TAG];
    
    if (!isFileSearchFinished) {
        [loadingIndicator setHidden:NO];
        [checkBoxBtn setHidden:YES];
        [fileNameLbl setHidden:YES];
        [loadingIndicator startAnimating];
    }else{
        [loadingIndicator setHidden:YES];
        [fileNameLbl setHidden:NO];
        if (firmwareFilesListArray.count == 0) {
            [checkBoxBtn setHidden:YES];
            fileNameLbl.text = LOCALIZEDSTRING(@"fileNotAvailableMessage");
        }else if (_selectedUpgradeMode == app_stack_separate &&
                  [upgradeButton.titleLabel.text isEqualToString:UPGRADE_BTN_TITLE_DEFAULT] &&
                  firmwareFilesListArray.count <= 1){
            
            [checkBoxBtn setHidden:YES];
            fileNameLbl.text = LOCALIZEDSTRING(@"fileNotAvailableMessage");
        }else{
            [checkBoxBtn setHidden:NO];
            [checkBoxBtn setSelected:NO];
            
            if (_selectedUpgradeMode == app_stack_separate && selectedFirmwareFilesArray.count == 1) {
                NSString * selectedFileStoragePath = [NSString pathWithComponents:[NSArray arrayWithObjects:[[selectedFirmwareFilesArray objectAtIndex:0] valueForKey:FILE_PATH],[[selectedFirmwareFilesArray objectAtIndex:0] valueForKey:FILE_NAME], nil]];
                NSString * indexPathFileStoragePath = [NSString pathWithComponents:[NSArray arrayWithObjects:[[firmwareFilesListArray objectAtIndex:indexPath.row] valueForKey:FILE_PATH],[[firmwareFilesListArray objectAtIndex:indexPath.row] valueForKey:FILE_NAME], nil]];
                if ([selectedFileStoragePath isEqualToString:indexPathFileStoragePath]) {
                    if (!isStackFileSelected) {
                        [checkBoxBtn setSelected:YES];
                    }
                }
            }else if (_selectedUpgradeMode == app_stack_separate && selectedFirmwareFilesArray.count == 2){
                NSString * selectedFileStoragePath = [NSString pathWithComponents:[NSArray arrayWithObjects:[[selectedFirmwareFilesArray objectAtIndex:0] valueForKey:FILE_PATH],[[selectedFirmwareFilesArray objectAtIndex:1] valueForKey:FILE_NAME], nil]];
                NSString * indexPathFileStoragePath = [NSString pathWithComponents:[NSArray arrayWithObjects:[[firmwareFilesListArray objectAtIndex:indexPath.row] valueForKey:FILE_PATH],[[firmwareFilesListArray objectAtIndex:indexPath.row] valueForKey:FILE_NAME], nil]];
                if ([selectedFileStoragePath isEqualToString:indexPathFileStoragePath]) {
                    [checkBoxBtn setSelected:YES];
                }
            }else if (_selectedUpgradeMode != app_stack_separate && selectedFirmwareFilesArray.count == 1){
                NSString * selectedFileStoragePath = [NSString pathWithComponents:[NSArray arrayWithObjects:[[selectedFirmwareFilesArray objectAtIndex:0] valueForKey:FILE_PATH],[[selectedFirmwareFilesArray objectAtIndex:0] valueForKey:FILE_NAME], nil]];
                NSString * indexPathFileStoragePath = [NSString pathWithComponents:[NSArray arrayWithObjects:[[firmwareFilesListArray objectAtIndex:indexPath.row] valueForKey:FILE_PATH],[[firmwareFilesListArray objectAtIndex:indexPath.row] valueForKey:FILE_NAME], nil]];
                if ([selectedFileStoragePath isEqualToString:indexPathFileStoragePath]) {
                    [checkBoxBtn setSelected:YES];
                }
            }
            fileNameLbl.text = [[firmwareFilesListArray objectAtIndex:indexPath.row] valueForKey:FILE_NAME];
        }
    }
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!firmwareFilesListArray || firmwareFilesListArray.count == 0) {
        
        // The value is returned as one to set the "File not available" text in the table. The user must check the count of firmwareFilesListArray before adding values to the cells of table.
        return 1;
    }
    return firmwareFilesListArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_selectedUpgradeMode == app_stack_separate && selectedFirmwareFilesArray.count >= 1) {
        NSString * selectedFileStoragePath = [NSString pathWithComponents:[NSArray arrayWithObjects:[[selectedFirmwareFilesArray objectAtIndex:0] valueForKey:FILE_PATH],[[selectedFirmwareFilesArray objectAtIndex:0] valueForKey:FILE_NAME], nil]];
        NSString * indexPathFileStoragePath = [NSString pathWithComponents:[NSArray arrayWithObjects:[[firmwareFilesListArray objectAtIndex:indexPath.row] valueForKey:FILE_PATH],[[firmwareFilesListArray objectAtIndex:indexPath.row] valueForKey:FILE_NAME], nil]];
        if ([selectedFileStoragePath isEqualToString:indexPathFileStoragePath]) {
            if (isStackFileSelected) {
                return 0.0f;
            }
        }
    }
    return 65.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIButton * checkBoxBtn = (UIButton *) [[tableView cellForRowAtIndexPath:indexPath].contentView viewWithTag:15];
    [self checkBoxButtonClicked:checkBoxBtn];
}

/*!
 *  @method checkBoxButtonClicked:
 *
 *  @discussion Method - Does the same function as table cell selection
 *
 */

- (IBAction)checkBoxButtonClicked:(UIButton *)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:fileListTable];
    NSIndexPath *indexPath = [fileListTable indexPathForRowAtPoint:buttonPosition];
    
    if (isFileSearchFinished && firmwareFilesListArray.count > 0 ) {
        if (!selectedFirmwareFilesArray) {
            selectedFirmwareFilesArray = [NSMutableArray new];
        }
        
        if(sender.selected)
        {
            if ([fileListTable cellForRowAtIndexPath:indexPath].tag == selectedFirmwareFilesArray.count)
                [selectedFirmwareFilesArray removeObjectAtIndex:[fileListTable cellForRowAtIndexPath:indexPath].tag-1];
            else
                [selectedFirmwareFilesArray removeObjectAtIndex:[fileListTable cellForRowAtIndexPath:indexPath].tag];
            
            [fileListTable reloadData];
            
        }else{
            if (_selectedUpgradeMode == app_stack_separate && [upgradeButton.titleLabel.text isEqualToString:UPGRADE_BTN_TITLE_DEFAULT] && selectedFirmwareFilesArray.count == 2) {
                [selectedFirmwareFilesArray removeObjectAtIndex:1];
            }else if ((selectedFirmwareFilesArray.count == 1 && _selectedUpgradeMode != app_stack_separate) || (_selectedUpgradeMode == app_stack_separate  && [upgradeButton.titleLabel.text isEqualToString:UPGRADE_BTN_TITLE_FOR_SEPERATE_SELECTION] && selectedFirmwareFilesArray.count == 1)){
                [selectedFirmwareFilesArray removeObjectAtIndex:0];
            }
            if (selectedFirmwareFilesArray.count < 2) {
                if((_selectedUpgradeMode == app_stack_separate && isStackFileSelected) || (selectedFirmwareFilesArray.count == 0)){
                    [fileListTable cellForRowAtIndexPath:indexPath].tag = selectedFirmwareFilesArray.count;
                    [selectedFirmwareFilesArray addObject:[firmwareFilesListArray objectAtIndex:indexPath.row]];
                }
            }
            [fileListTable reloadData];
        }
    }

}



@end
