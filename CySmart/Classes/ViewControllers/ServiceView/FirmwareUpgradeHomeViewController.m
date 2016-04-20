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
#import "FirmwareUpgradeHomeViewController.h"
#import "FirmwareFileSelectionViewController.h"
#import "OTAFileParser.h"
#import "BootLoaderServiceModel.h"
#import "Utilities.h"
#import "CBManager.h"

#define BACK_BUTTON_ALERT_TAG  200

#define UPGRADE_RESUME_ALERT_TAG 201
#define UPGRADE_STOP_ALERT_TAG  202

#define APP_UPGRADE_BTN_TAG 203
#define APP_STACK_UPGRADE_COMBINED_BTN_TAG  204
#define APP_STACK_UPGRADE_SEPARATE_BTN_TAG  205

#define MAX_DATA_SIZE   133

#define FIRMWARE_SELECTION_SEGUE    @"firmwareSelectionPageSegue"

/*!
 *  @class FirmwareUpgradeHomeViewController
 *
 *  @discussion Class to handle user interaction, UI update and firmware upgrade
 *
 */

@interface FirmwareUpgradeHomeViewController () <FirmwareFileSelectionDelegate, UIAlertViewDelegate>
{
    IBOutlet UIButton * applicationUpgradeBtn;
    IBOutlet UIButton * applicationAndStackUpgradeCombinedBtn;
    IBOutlet UIButton * applicationAndStackUpgradeSeparateBtn;
    IBOutlet UIButton * startStopUpgradeBtn;
    
    IBOutlet UILabel * currentOperationLabel;
    IBOutlet UILabel * firmwareFile1NameLabel;
    IBOutlet UILabel * firmwareFile2NameLabel;
    IBOutlet UILabel * firmwareFile1UpgradePercentageLabel;
    IBOutlet UILabel * firmwareFile2UpgradePercentageLabel;
    
    IBOutlet UIView * firmwareFile1NameContainerView;
    IBOutlet UIView * firmwareFile2NameContainerView;
    
    //Constraint Outlets for modifying UI for screen fit
    IBOutlet NSLayoutConstraint * titleLabelTopSpaceConstraint;
    IBOutlet NSLayoutConstraint * firstBtnTopSpaceConstraint;
    IBOutlet NSLayoutConstraint * secondBtnTopSpaceonstraint;
    IBOutlet NSLayoutConstraint * thirdBtnTopSpaceConstraint;
    IBOutlet NSLayoutConstraint * statusLabelTopSpaceConstraint;
    IBOutlet NSLayoutConstraint * progressLabel1TopSpaceConstraint;
    IBOutlet NSLayoutConstraint * progressLabel2TopSpaceConstraint;
    
    IBOutlet NSLayoutConstraint * firmwareUpgradeProgressLabel1TrailingSpaceConstraint;
    IBOutlet NSLayoutConstraint * firmwareUpgradeProgressLabel2TrailingSpaceConstraint;

    BootLoaderServiceModel *bootLoaderModel;
    BOOL isBootLoaderCharacteristicFound, isWritingFile1;
    
    NSArray * firmwareFilesArray, *firmWareRowDataArray;
    NSMutableArray *currentRowDataArray;
    
    NSDictionary *fileHeaderDictionary;
    OTAMode firmwareUpgradeMode;
    int currentRowNumber, currentIndex;
    NSString *currentArrayID;
    int fileWritingProgress;
}

@end

@implementation FirmwareUpgradeHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initiateView];
    [self initServiceModel];
    
    isWritingFile1 = YES;
    // Check for multiple files
    
    if ([[CBManager sharedManager] bootLoaderFilesArray] != nil)
    {
        [self.view layoutIfNeeded];
        [self firmwareFilesSelected:[[CBManager sharedManager] bootLoaderFilesArray] forUpgradeMode:app_stack_separate];
        
        firmwareUpgradeProgressLabel1TrailingSpaceConstraint.constant = 0.0;
        firmwareUpgradeProgressLabel2TrailingSpaceConstraint.constant = firmwareFile2NameContainerView.frame.size.width;
        
        [firmwareFile1UpgradePercentageLabel setHidden:NO];
        [firmwareFile1UpgradePercentageLabel setText:@"100 %"];
        
        [firmwareFile2UpgradePercentageLabel setHidden:NO];
        [firmwareFile2UpgradePercentageLabel setText:@"0 %"];
        
        UIAlertView *updateAlert = [[UIAlertView alloc] initWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTAUpgradeResumeConfirmMessage") delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        updateAlert.tag = UPGRADE_RESUME_ALERT_TAG;
        [updateAlert show];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[super navBarTitleLabel] setText:FIRMWARE_UPGRADE];
    
    // Adding custom back button
    UIBarButtonItem * backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:BACK_BUTTON_IMAGE] landscapeImagePhone:[UIImage imageNamed:BACK_BUTTON_IMAGE] style:UIBarButtonItemStyleDone target:self action:@selector(backbuttonPressed)];
    self.navigationItem.leftBarButtonItem = backButton;
    self.navigationItem.leftBarButtonItem.imageInsets = UIEdgeInsetsMake(0, -5, 0, 0);

}


-(void) backbuttonPressed
{
    if (!startStopUpgradeBtn.hidden)
    {
        UIAlertView *upgradeInterruptAlert = [[UIAlertView alloc] initWithTitle:APP_NAME message:LOCALIZEDSTRING(@"upgradeProgressAlert") delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        upgradeInterruptAlert.tag = BACK_BUTTON_ALERT_TAG;
        [upgradeInterruptAlert show];
    }
    else
        [self.navigationController popViewControllerAnimated:YES];

}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    if (![self.navigationController.viewControllers containsObject:self])
    {
        [bootLoaderModel stopUpdate];
    }
    
    // removing the custom back button
    if (self.navigationItem.leftBarButtonItem != nil)
    {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

/*!
 *  @method initiateView
 *
 *  @discussion Method - Setting the view initially or resets it into inital mode when required.
 *
 */
- (void) initiateView
{
    applicationAndStackUpgradeCombinedBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    applicationAndStackUpgradeSeparateBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    //Setting button view properties programatically.
    applicationUpgradeBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    applicationUpgradeBtn.layer.shadowOpacity = .5;
    applicationUpgradeBtn.layer.shadowRadius = 3;
    applicationUpgradeBtn.layer.shadowOffset = CGSizeZero;
    [applicationUpgradeBtn setBackgroundColor:[UIColor whiteColor]];
    [applicationUpgradeBtn setSelected:NO];
    
    applicationAndStackUpgradeCombinedBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    applicationAndStackUpgradeCombinedBtn.layer.shadowOpacity = 0.5;
    applicationAndStackUpgradeCombinedBtn.layer.shadowRadius = 3;
    applicationAndStackUpgradeCombinedBtn.layer.shadowOffset = CGSizeZero;
    [applicationAndStackUpgradeCombinedBtn setBackgroundColor:[UIColor whiteColor]];
    [applicationAndStackUpgradeCombinedBtn setSelected:NO];
    
    applicationAndStackUpgradeSeparateBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    applicationAndStackUpgradeSeparateBtn.layer.shadowOpacity = 0.5;
    applicationAndStackUpgradeSeparateBtn.layer.shadowRadius = 3;
    applicationAndStackUpgradeSeparateBtn.layer.shadowOffset = CGSizeZero;
    [applicationAndStackUpgradeSeparateBtn setBackgroundColor:[UIColor whiteColor]];
    [applicationAndStackUpgradeSeparateBtn setSelected:NO];
    
    [startStopUpgradeBtn setHidden:YES];
    [startStopUpgradeBtn setSelected:NO];
    [firmwareFile1NameContainerView setHidden:YES];
    [firmwareFile2NameContainerView setHidden:YES];
    [currentOperationLabel setHidden:YES];
    [firmwareFile1UpgradePercentageLabel setHidden:YES];
    [firmwareFile2UpgradePercentageLabel setHidden:YES];
    firmwareUpgradeProgressLabel1TrailingSpaceConstraint.constant = firmwareFile1NameContainerView.frame.size.width;
    firmwareUpgradeProgressLabel2TrailingSpaceConstraint.constant = firmwareFile2NameContainerView.frame.size.width;
    
    if (self.view.frame.size.height <= 480) {
        titleLabelTopSpaceConstraint.constant = 15;
        firstBtnTopSpaceConstraint.constant = 15;
        secondBtnTopSpaceonstraint.constant = 15;
        thirdBtnTopSpaceConstraint.constant = 15;
        statusLabelTopSpaceConstraint.constant = 15;
        progressLabel2TopSpaceConstraint.constant = 10;
        [self.view layoutIfNeeded];
    }
}

#pragma mark - Button Events

/*!
 *  @method applicationUpgradeBtnTouched:
 *
 *  @discussion Method - Common Action method for the 3 upgrade mode button
 *
 */
- (IBAction)applicationUpgradeBtnTouched:(UIButton *)sender
{
    if (!startStopUpgradeBtn.selected) {
        [self performSegueWithIdentifier:FIRMWARE_SELECTION_SEGUE sender:sender];
    }
}

/*!
 *  @method startStopBtnTouched:
 *
 *  @discussion Method - Action method of upgrade start/stop button
 *
 */

- (IBAction)startStopBtnTouched:(UIButton *)sender
{
    if (sender.selected) {
        
        UIAlertView *stopUpdateAlert = [[UIAlertView alloc] initWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTAUpgradeCancelConfirmMessage") delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        stopUpdateAlert.tag = UPGRADE_STOP_ALERT_TAG;
        [stopUpdateAlert show];
        
    }else{
        
        [sender setSelected:YES];
        if (firmwareFilesArray) {
            [currentOperationLabel setText:LOCALIZEDSTRING(@"OTAUpgradeInProgressMessage")];
            [firmwareFile1UpgradePercentageLabel setHidden:NO];
            if (firmwareUpgradeMode == app_stack_separate) {
                [firmwareFile2UpgradePercentageLabel setHidden:NO];
                [firmwareFile2UpgradePercentageLabel setText:@"0 %"];
            }
            
            if (isWritingFile1)
            {
                [firmwareFile1UpgradePercentageLabel setText:@"0 %"];
                [self startParsingFirmwareFile:[firmwareFilesArray objectAtIndex:0]];
            }
            else
            {
                [firmwareFile2UpgradePercentageLabel setText:@"0 %"];
                [self startParsingFirmwareFile:[firmwareFilesArray objectAtIndex:1]];
            }
        }
    }
}

#pragma mark - Send files for parsing

/*!
 *  @method startParsingFirmwareFile:
 *
 *  @discussion Method for handling the file parsing call and callback
 *
 */
- (void) startParsingFirmwareFile:(NSDictionary *)firmwareFile
{
    OTAFileParser * fileParser = [OTAFileParser new];
    
    [fileParser parseFirmwareFileWithName:[firmwareFile valueForKey:FILE_NAME] andPath:[firmwareFile valueForKey:FILE_PATH] onFinish:^(NSMutableDictionary *header, NSArray *rowData,NSArray *rowIdArray, NSError * error) {
        
        if (header && rowData && rowIdArray && !error) {
            fileHeaderDictionary = header;
            firmWareRowDataArray = rowData;
            [self initializeFileTransfer];
            
        }else if(error){
            [Utilities alert:APP_NAME Message:error.localizedDescription];
            [self initiateView];
        }
    }];
}

#pragma mark - FirmwareFileSelection Delegate Methods

/*!
 *  @method firmwareFilesSelected: forUpgradeMode:
 *
 *  @discussion Method - Delegate method to recieve files passed from FileSelection View Controller
 *
 */

- (void)firmwareFilesSelected:(NSArray *)selectedFilesArray forUpgradeMode:(OTAMode)selectedMode
{
    if (selectedFilesArray) {
        
        firmwareFilesArray = [[NSArray alloc] initWithArray:selectedFilesArray];
        firmwareUpgradeMode = selectedMode;
        
        [self initiateView];
        [startStopUpgradeBtn setHidden:NO];
        [currentOperationLabel setHidden:NO];
        [firmwareFile1NameContainerView setHidden:NO];
        
        firmwareFile1NameLabel.text = [[[selectedFilesArray objectAtIndex:0] valueForKey:FILE_NAME] stringByDeletingPathExtension];
        
        if (selectedMode == app_stack_separate) {
            [firmwareFile2NameContainerView setHidden:NO];
            [applicationAndStackUpgradeSeparateBtn setSelected:YES];
            [applicationAndStackUpgradeSeparateBtn setBackgroundColor:[UIColor colorWithRed:12.0f/255.0f green:55.0f/255.0f blue:123.0f/255.0f alpha:1.0f]];
            firmwareFile2NameLabel.text = [[[selectedFilesArray objectAtIndex:1] valueForKey:FILE_NAME] stringByDeletingPathExtension];
            currentOperationLabel.text = LOCALIZEDSTRING(@"OTAFileSelectedMessage");
        }else{
            currentOperationLabel.text = LOCALIZEDSTRING(@"OTAFileSelectedMessage");
            if(selectedMode == app_upgrade)
            {
                [applicationUpgradeBtn setSelected:YES];
                [applicationUpgradeBtn setBackgroundColor:[UIColor colorWithRed:12.0f/255.0f green:55.0f/255.0f blue:123.0f/255.0f alpha:1.0f]];
            }else{
                [applicationAndStackUpgradeCombinedBtn setSelected:YES];
                [applicationAndStackUpgradeCombinedBtn setBackgroundColor:[UIColor colorWithRed:12.0f/255.0f green:55.0f/255.0f blue:123.0f/255.0f alpha:1.0f]];
            }
        }
        
        if ([[CBManager sharedManager] bootLoaderFilesArray] == nil)
        {
            [self startStopBtnTouched:startStopUpgradeBtn];
        }
    }
}

#pragma mark - Segue Methods
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIButton * senderBtn = (UIButton *)sender;
    
    FirmwareFileSelectionViewController * destView = [segue destinationViewController];
    destView.delegate = self;
    if (senderBtn.tag == APP_UPGRADE_BTN_TAG) {
        destView.selectedUpgradeMode = app_upgrade;
    }else if (senderBtn.tag == APP_STACK_UPGRADE_COMBINED_BTN_TAG){
        destView.selectedUpgradeMode = app_stack_combined;
    }else if (senderBtn.tag == APP_STACK_UPGRADE_SEPARATE_BTN_TAG){
        destView.selectedUpgradeMode = app_stack_separate;
    }
}

#pragma mark - OTA Upgrade

/*!
 *  @method initServiceModel
 *
 *  @discussion Method to initialize the bootloader model
 *
 */

-(void) initServiceModel
{
    if (!bootLoaderModel)
    {
        bootLoaderModel = [[BootLoaderServiceModel alloc] init];
    }
    
    [bootLoaderModel discoverCharacteristicsWithCompletionHandler:^(BOOL success, NSError *error) {
        
        if (success)
        {
            isBootLoaderCharacteristicFound = YES;
        }
    }];
}

/*!
 *  @method initializeFileTransfer
 *
 *  @discussion Method to begin the file transter
 *
 */
-(void) initializeFileTransfer
{
    if (isBootLoaderCharacteristicFound)
    {
        currentIndex = 0;
        [self handleCharacteristicUpdates];
        
        // Set the checksum type
        
        if ([[fileHeaderDictionary objectForKey:CHECKSUM_TYPE] integerValue])
        {
            [bootLoaderModel setCheckSumType:CRC_16];
        }
        else
            [bootLoaderModel setCheckSumType:CHECK_SUM];
        
        /* Write the ENTER_BOOTLOADER command */
        NSData *data = [bootLoaderModel createCommandPacketWithCommand:ENTER_BOOTLOADER dataLength:0 data:nil];
        [bootLoaderModel writeValueToCharacteristicWithData:data bootLoaderCommandCode:ENTER_BOOTLOADER];
    }
}

/*!
 *  @method handleCharacteristicUpdates
 *
 *  @discussion Method to handle the characteristic value updates
 *
 */

-(void) handleCharacteristicUpdates
{
    [bootLoaderModel updateValueForCharacteristicWithCompletionHandler:^(BOOL success, id commandCode, NSError *error)
     {
         if (success)
         {
             [self handleResponseFromCharacteristicForCommand:commandCode];
         }
     }];
}

/*!
 *  @method handleResponseFromCharacteristicForCommand:
 *
 *  @discussion Method to handle the file tranfer with the response from the device
 *
 */

-(void) handleResponseFromCharacteristicForCommand:(id)commandCode
{
    if ([commandCode isEqual:@(ENTER_BOOTLOADER)])
    {
        // Compare silicon id and silicon rev string
        
        if ([[[fileHeaderDictionary objectForKey:SILICON_ID] lowercaseString] isEqualToString:bootLoaderModel.siliconIDString] && [[fileHeaderDictionary objectForKey:SILICON_REV] isEqualToString:bootLoaderModel.siliconRevString])
        {
            /* Write the GET_FLASH_SIZE command */
            
            NSDictionary *rowDataDict = [firmWareRowDataArray objectAtIndex:currentIndex];
            NSDictionary *dataDict = [NSDictionary dictionaryWithObject:[rowDataDict objectForKey:ARRAY_ID] forKey:FLASH_ARRAY_ID];
            NSData *data = [bootLoaderModel createCommandPacketWithCommand:GET_FLASH_SIZE dataLength:1 data:dataDict];
            
            // Initilaize the arrayID
            currentArrayID = [rowDataDict objectForKey:ARRAY_ID];
            [bootLoaderModel writeValueToCharacteristicWithData:data bootLoaderCommandCode:GET_FLASH_SIZE];
        }
        else
        {
            [Utilities alert:APP_NAME Message:LOCALIZEDSTRING(@"OTASiliconIDMismatchMessage")];
            // Reset the view if an error occurs
            [self initiateView];
        }
    }
    else if ([commandCode isEqual:@(GET_FLASH_SIZE)])
    {
        [self writeFirmWareFileDataAtIndex:currentIndex];
    }
    else if ([commandCode isEqual:@(SEND_DATA)])
    {        
        if (bootLoaderModel.isWritePacketDataSuccess)
        {
            [self writeCurrentRowDataArrayAtIndex:currentIndex];
        }
        else
        {
            [Utilities alert:APP_NAME Message:LOCALIZEDSTRING(@"OTASendDataCommandFailed")];
        }
    }
    else if ([commandCode isEqual:@(PROGRAM_ROW)])
    {
        // check the row check sum
        
        if (bootLoaderModel.isWriteRowDataSuccess)
        {
            /* Write the VERIFY_ROW command */
            
            NSDictionary *rowDataDict = [firmWareRowDataArray objectAtIndex:currentIndex];
            NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:[rowDataDict objectForKey:ARRAY_ID],FLASH_ARRAY_ID,
                                      @(currentRowNumber),FLASH_ROW_NUMBER,
                                      nil];
            NSData *verifyRowData = [bootLoaderModel createCommandPacketWithCommand:VERIFY_ROW dataLength:3 data:dataDict];
            [bootLoaderModel writeValueToCharacteristicWithData:verifyRowData bootLoaderCommandCode:VERIFY_ROW];
        }
        else
        {
            [Utilities alert:APP_NAME Message:LOCALIZEDSTRING(@"OTAWritingFailedMessage")];
            [self initiateView];
        }
    }
    else if ([commandCode isEqual:@(VERIFY_ROW)])
    {
        /* Compare the checksum received from the device and that from the file row  */
        
        NSDictionary *rowDataDict = [firmWareRowDataArray objectAtIndex:currentIndex];
        
        uint8_t rowCheckSum = [Utilities getIntegerFromHexString:[rowDataDict objectForKey:CHECKSUM_OTA]];
        uint8_t arrayID = [Utilities getIntegerFromHexString:[rowDataDict objectForKey:ARRAY_ID]];
        
        unsigned short rowNumber = [Utilities getIntegerFromHexString:[rowDataDict objectForKey:ROW_NUMBER]];
        unsigned short dataLength = [Utilities getIntegerFromHexString:[rowDataDict objectForKey:DATA_LENGTH]];
        
        uint8_t sum = rowCheckSum + arrayID + rowNumber + (rowNumber >> 8) + dataLength + (dataLength >> 8);
        
        if (sum == bootLoaderModel.checkSum)
        {
            currentIndex ++;
            
            /* UI update with the file writing progress */
            float percentage = ( (float) currentIndex/firmWareRowDataArray.count)* 100 ;
            
            fileWritingProgress = (firmwareFile1NameContainerView.frame.size.width * currentIndex)/firmWareRowDataArray.count;
            if (isWritingFile1) {
                firmwareUpgradeProgressLabel1TrailingSpaceConstraint.constant = firmwareFile1NameContainerView.frame.size.width - fileWritingProgress;
                firmwareFile1UpgradePercentageLabel.text = [NSString stringWithFormat:@"%d %%",(int)percentage];
            }else{
                firmwareUpgradeProgressLabel2TrailingSpaceConstraint.constant = firmwareFile2NameContainerView.frame.size.width - fileWritingProgress;
                firmwareFile2UpgradePercentageLabel.text = [NSString stringWithFormat:@"%d %%",(int)percentage];
            }
            
            [UIView animateWithDuration:0.5 animations:^{
                [self.view layoutIfNeeded];
            }];
            
            // Writing the next line from file
            if (currentIndex < firmWareRowDataArray.count)
            {
                [self writeFirmWareFileDataAtIndex:currentIndex];
            }
            else
            {
                /* Write VERIFY_CHECKSUM command */
                NSData *data = [bootLoaderModel createCommandPacketWithCommand:VERIFY_CHECKSUM dataLength:0 data:nil];
                [bootLoaderModel writeValueToCharacteristicWithData:data bootLoaderCommandCode:VERIFY_CHECKSUM];
            }
        }
        else
        {
            [Utilities alert:APP_NAME Message:LOCALIZEDSTRING(@"OTAChecksumMismatchMessage")];
            [self initiateView];
            currentIndex = 0;
        }
    }
    else if ([commandCode isEqual:@(VERIFY_CHECKSUM)])
    {
        if (bootLoaderModel.isApplicationValid)
        {
            [currentOperationLabel setText:LOCALIZEDSTRING(@"OTAUpgradeCompletedMessage")];
            
            // Storing the selected files
            
            if (firmwareUpgradeMode == app_stack_separate && isWritingFile1)
            {
                [[CBManager sharedManager] setBootLoaderFilesArray:firmwareFilesArray];
                [[UIApplication sharedApplication] cancelAllLocalNotifications];
                UILocalNotification* n1 = [[UILocalNotification alloc] init];
                n1.fireDate = [NSDate dateWithTimeIntervalSinceNow: 5];
                n1.alertBody = LOCALIZEDSTRING(@"OTAAppUgradePendingMessage");
                [[UIApplication sharedApplication] scheduleLocalNotification: n1];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:LOCALIZEDSTRING(@"OTAUpgradeStatus")];
            }else{
                [[UIApplication sharedApplication] cancelAllLocalNotifications];
                UILocalNotification* n1 = [[UILocalNotification alloc] init];
                n1.fireDate = [NSDate dateWithTimeIntervalSinceNow: 5];
                n1.alertBody = LOCALIZEDSTRING(@"OTAUpgradeCompletedMessage");
                [[UIApplication sharedApplication] scheduleLocalNotification: n1];
            }
            
            /* Write EXIT_BOOTLOADER command */
            
            NSData *exitBootloaderCommandData = [bootLoaderModel createCommandPacketWithCommand:EXIT_BOOTLOADER dataLength:0 data:nil];
            [bootLoaderModel writeValueToCharacteristicWithData:exitBootloaderCommandData bootLoaderCommandCode:EXIT_BOOTLOADER];
        }
        else
        {
            [Utilities alert:APP_NAME Message:LOCALIZEDSTRING(@"OTAInvalidApplicationMessage")];
            [self initiateView];
            currentIndex = 0;
        }
    }
}

/*!
 *  @method writeFirmWareFileDataAtIndex:
 *
 *  @discussion Method to write the firmware file data to the device
 *
 */

-(void) writeFirmWareFileDataAtIndex:(int) index
{
    NSDictionary *rowDataDict = [firmWareRowDataArray objectAtIndex:index];
    
    // Check for change in arrayID
    
    if (![[rowDataDict objectForKey:ARRAY_ID] isEqual:currentArrayID])
    {
        // GET_FLASH_SIZE command is passed to get the new start and end row numbers
        NSDictionary *rowDataDictionary = [firmWareRowDataArray objectAtIndex:index];
        NSDictionary *dict = [NSDictionary dictionaryWithObject:[rowDataDictionary objectForKey:ARRAY_ID] forKey:FLASH_ARRAY_ID];
        NSData *data = [bootLoaderModel createCommandPacketWithCommand:GET_FLASH_SIZE dataLength:1 data:dict];
        [bootLoaderModel writeValueToCharacteristicWithData:data bootLoaderCommandCode:GET_FLASH_SIZE];
        
        currentArrayID = [rowDataDictionary objectForKey:ARRAY_ID];
        return;
    }
    
    // Check whether the row number falls in the range obtained from the device
    currentRowNumber = [Utilities getIntegerFromHexString:[rowDataDict objectForKey:ROW_NUMBER]];
    
    if (currentRowNumber >= bootLoaderModel.startRowNumber && currentRowNumber <= bootLoaderModel.endRowNumber)
    {
        /* Write data using PROGRAM_ROW command */
        
       currentRowDataArray = [[rowDataDict objectForKey:DATA_ARRAY] mutableCopy];
        [self writeCurrentRowDataArrayAtIndex:index];
    }
    else
    {
        [Utilities alert:APP_NAME Message:LOCALIZEDSTRING(@"OTARowNoOutOfBoundMessage")];
        [self initiateView];
        currentIndex = 0;
    }
}
/*!
 *  @method writeCurrentRowDataArrayAtIndex:
 *
 *  @discussion Method to write the data in a row
 *
 */
-(void) writeCurrentRowDataArrayAtIndex:(int)index
{
    NSDictionary *rowDataDict = [firmWareRowDataArray objectAtIndex:index];

    if (currentRowDataArray.count > MAX_DATA_SIZE)
    {
        NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:[currentRowDataArray subarrayWithRange:NSMakeRange(0, MAX_DATA_SIZE)],ROW_DATA, nil];
        NSData *data = [bootLoaderModel createCommandPacketWithCommand:SEND_DATA dataLength:MAX_DATA_SIZE data:dataDict];
        [bootLoaderModel writeValueToCharacteristicWithData:data bootLoaderCommandCode:SEND_DATA];
        
        [currentRowDataArray removeObjectsInRange:NSMakeRange(0, MAX_DATA_SIZE)];
    }
    else
    {
        NSDictionary *lastPacketDict = [NSDictionary dictionaryWithObjectsAndKeys:[rowDataDict objectForKey:ARRAY_ID],FLASH_ARRAY_ID,
                                        @(currentRowNumber),FLASH_ROW_NUMBER,
                                        currentRowDataArray,ROW_DATA, nil];
        NSData *lastChunkData = [bootLoaderModel createCommandPacketWithCommand:PROGRAM_ROW dataLength:currentRowDataArray.count+3 data:lastPacketDict];
        [bootLoaderModel writeValueToCharacteristicWithData:lastChunkData bootLoaderCommandCode:PROGRAM_ROW];
    }
}

#pragma mark - alertView delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == BACK_BUTTON_ALERT_TAG)
    {
        if (buttonIndex)
        {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
    if (alertView.tag == UPGRADE_RESUME_ALERT_TAG) {
        if (buttonIndex == 1)
        {
            isWritingFile1 = NO;
            [self startStopBtnTouched:startStopUpgradeBtn];
            [[CBManager sharedManager] setBootLoaderFilesArray:nil];
        }
        else
        {
            [[CBManager sharedManager] setBootLoaderFilesArray:nil];
            [self initiateView];
        }
    }else if (alertView.tag == UPGRADE_STOP_ALERT_TAG)
    {
        
        if (buttonIndex == 1) {
            
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    int differenceInWidth = self.view.frame.size.height - self.view.frame.size.width;
    if (startStopUpgradeBtn.selected) {
        if (isWritingFile1) {
            firmwareUpgradeProgressLabel1TrailingSpaceConstraint.constant = (firmwareFile1NameContainerView.frame.size.width+differenceInWidth) - fileWritingProgress;
        }else{
            firmwareUpgradeProgressLabel2TrailingSpaceConstraint.constant = (firmwareFile2NameContainerView.frame.size.width+differenceInWidth) - fileWritingProgress;
        }
    }else{
        firmwareUpgradeProgressLabel1TrailingSpaceConstraint.constant = firmwareFile1NameContainerView.frame.size.width+differenceInWidth;
        firmwareUpgradeProgressLabel2TrailingSpaceConstraint.constant = firmwareFile2NameContainerView.frame.size.width+differenceInWidth;
    }
}

@end
