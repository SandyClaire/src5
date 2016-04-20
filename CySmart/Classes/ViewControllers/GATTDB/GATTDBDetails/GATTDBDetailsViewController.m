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

#import "GATTDBDetailsViewController.h"
#import "GATTDBDescriptorListViewController.h"
#import "CBManager.h"
#import "Utilities.h"
#import "MRHexKeyboard.h"
#import "ResourceHandler.h"
#import "Constants.h"
#import "LoggerHandler.h"

#define DESCRIPTOR_LIST_SEGUE       @"descriptorListSegue"

#define HEX_ALERTVIEW_TAG       101
#define ASCII_ALERTVIEW_TAG     102


#define ASCIIT_TEXFIELD_TAG     103
#define HEX_TEXTFIELD_TAG       104

/*!
 *  @class GATTDBDetailsViewController
 *
 *  @discussion Class to handle the characteristic value display and characteristic property related operations
 *
 */
@interface GATTDBDetailsViewController ()<cbCharacteristicManagerDelegate,UIAlertViewDelegate, UITextFieldDelegate>
{
    MRHexKeyboard *hexKeyboard;
    UIAlertView *enterHexAlert, *enterASCIIAlert;
    UITextField *hexAlertTextField, *ASCIIAlertTextField;
    
    void(^characteristicWriteCompletionHandler)(BOOL success,NSError *error);
}

/* Datafields */
@property (weak, nonatomic) IBOutlet UILabel *serviceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *characteristicNameLabel;

@property (weak, nonatomic) IBOutlet UITextField *ASCIIValueTextField;
@property (weak, nonatomic) IBOutlet UITextField *hexValueTextField;

@property (weak, nonatomic) IBOutlet UILabel *dateValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeValueLabel;
@property (weak, nonatomic) IBOutlet UIButton *descriptorButton;
@property (weak, nonatomic) IBOutlet UIView *bottomView;

/* Buttons and related constraints  */
@property (weak, nonatomic) IBOutlet UIButton *readButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *readButtonWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *readButtonCentreXConstraint;

@property (weak, nonatomic) IBOutlet UIButton *writeButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *writeButtonWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *writeButtonCentreXConstraint;

@property (weak, nonatomic) IBOutlet UIButton *notifyButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *notifyButtonWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *notifyButtonCentreXConstraint;

@property (weak, nonatomic) IBOutlet UIButton *indicateButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *indicateButtonWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *indicateButtonCentreXConstraint;


-(void) changeInDeviceOrientation:(NSNotification *)notification;

@end

@implementation GATTDBDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _descriptorButton.hidden = YES;
    [self checkDescriptorsForCharacteristic:[[CBManager sharedManager] myCharacteristic]];

    /* Add observer for handle the change in UI with device orientation */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeInDeviceOrientation:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self initView];
    [super viewWillAppear:animated];
    [[super navBarTitleLabel] setText:GATT_DB];
    [[CBManager sharedManager] setCbCharacteristicDelegate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [self.view endEditing:YES];
    [enterHexAlert dismissWithClickedButtonIndex:0 animated:NO];
}

/*!
 *  @method initView
 *
 *  @discussion Method to initilize the view when user enters the screen
 *
 */
-(void) initView
{
    // update characteristic and service name labels
    
    _serviceNameLabel.text = [ResourceHandler getServiceNameForUUID:[[CBManager sharedManager] myService].UUID];
    _characteristicNameLabel.text = [ResourceHandler getCharacteristicNameForUUID:[[CBManager sharedManager] myCharacteristic].UUID];

    // Adding buttons
    
    _readButtonCentreXConstraint.constant = 2 *self.view.frame.size.width;
    _writeButtonCentreXConstraint.constant = 2 *self.view.frame.size.width;
    _notifyButtonCentreXConstraint.constant = 2 *self.view.frame.size.width;
    _indicateButtonCentreXConstraint.constant = 2 *self.view.frame.size.width;
    
    int propertyCount = (int)[[CBManager sharedManager] characteristicProperties].count;
    int buttonWidth = self.view.frame.size.width/propertyCount;
    float centreXConstant;
    
    /* Setting the property button position and width */
    
    centreXConstant = -1 *((buttonWidth * (propertyCount - 1))*0.5);
    
    for (NSString *property in [[CBManager sharedManager] characteristicProperties])
    {
        if ([property isEqual:READ])
        {
            _readButtonCentreXConstraint.constant = centreXConstant;
            _readButtonWidthConstraint.constant = buttonWidth;
        }
        
        if ([property isEqual:WRITE])
        {
            _writeButtonCentreXConstraint.constant = centreXConstant;
            _writeButtonWidthConstraint.constant = buttonWidth;
        }
        
        if ([property isEqual:NOTIFY])
        {
            _notifyButtonCentreXConstraint.constant = centreXConstant;
            _notifyButtonWidthConstraint.constant = buttonWidth;
            
            if ([[CBManager sharedManager] myCharacteristic].isNotifying)
            {
                _notifyButton.selected = YES;
            }
            else
                _notifyButton.selected = NO;
        }
        
        if ([property isEqual:INDICATE])
        {
            _indicateButtonCentreXConstraint.constant = centreXConstant;
            _indicateButtonWidthConstraint.constant = buttonWidth;
            
            if ([[CBManager sharedManager] myCharacteristic].isNotifying)
            {
                _indicateButton.selected = YES;
            }
            else
                _indicateButton.selected = NO;
        }
        
        centreXConstant += buttonWidth;
    }
}

/*!
 *  @method checkDescriptorsForCharacteristic:
 *
 *  @discussion Method to initialize discovering descriptors for characteristic
 *
 */

-(void) checkDescriptorsForCharacteristic:(CBCharacteristic *)characteristic
{
    [[[CBManager sharedManager] myPeripheral] discoverDescriptorsForCharacteristic:characteristic];
}

/*!
 *  @method readButtonClicked:
 *
 *  @discussion Method to handle the read button click
 *
 */

- (IBAction)readButtonClicked:(UIButton *)sender
{
    [sender setSelected:YES];
    [[[CBManager sharedManager] myPeripheral] readValueForCharacteristic:[[CBManager sharedManager] myCharacteristic]];
    [self logButtonAction:READ_REQUEST]; // Log
    double delayInSeconds = 0.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [sender setSelected:NO];
    });
}

/*!
 *  @method writeButtonClicked :
 *
 *  @discussion Method to handle the write button click
 *
 */

- (IBAction)writeButtonClicked:(UIButton *)sender
{
    /* Show hex keyboard and textfield */
    [self showHexKeyboard];
}

/*!
 *  @method showHexKeyboard
 *
 *  @discussion Method to initilaize and show the hex keyboard
 *
 */

-(void) showHexKeyboard{
    
    if (!hexKeyboard)
    {
        hexKeyboard = [[MRHexKeyboard alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, KEYBOARD_HEIGHT)];
    }
    else
    {
        [hexKeyboard changeViewFrameSizeToframe:CGRectMake(0, 0, self.view.frame.size.width, KEYBOARD_HEIGHT)];
    }
    
    if (!enterHexAlert)
    {
        enterHexAlert = [[UIAlertView alloc] initWithTitle:LOCALIZEDSTRING(@"enterHexAlert") message:@"" delegate:self cancelButtonTitle:CANCEL otherButtonTitles:OK, nil];
        enterHexAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
        enterHexAlert.delegate = self;
        enterHexAlert.tag = HEX_ALERTVIEW_TAG;
    }
    
    hexAlertTextField = [enterHexAlert textFieldAtIndex:0];
    hexAlertTextField.inputView = [hexKeyboard initWithTextField:hexAlertTextField];
    hexAlertTextField.text = [[NSString stringWithFormat:@"0x%@",_hexValueTextField.text] stringByReplacingOccurrencesOfString:@" " withString:@" 0x"] ;
    hexKeyboard.orientation = [UIDevice currentDevice].orientation;
    hexKeyboard.isPresent = YES;
    [self addDoneButton];
    
    [enterHexAlert show];
}

/*!
 *  @method showASCIIKeyboard
 *
 *  @discussion Method to show enter ASCII alert and related keyboard
 *
 */
-(void) showASCIIKeyboard{
    
    if (!enterASCIIAlert)
    {
        enterASCIIAlert = [[UIAlertView alloc] initWithTitle:LOCALIZEDSTRING(@"enterASCIIAlert") message:@"" delegate:self cancelButtonTitle:CANCEL otherButtonTitles:OK, nil];
        enterASCIIAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
        enterASCIIAlert.delegate = self;
        enterASCIIAlert.tag = ASCII_ALERTVIEW_TAG;
    }
    
    ASCIIAlertTextField = [enterASCIIAlert textFieldAtIndex:0];
    ASCIIAlertTextField.text = _ASCIIValueTextField.text;
    [enterASCIIAlert show];
}

/*!
 *  @method notifyButtonClicked:
 *
 *  @discussion Method to handle notify button click
 *
 */

- (IBAction)notifyButtonClicked:(UIButton *)sender
{
    if (!sender.selected)
    {
        sender.selected = YES;
        [[[CBManager sharedManager] myPeripheral] setNotifyValue:YES forCharacteristic:[[CBManager sharedManager] myCharacteristic]];
        [self logButtonAction:START_NOTIFY];
    }
    else
    {
        sender.selected = NO;
        [[[CBManager sharedManager] myPeripheral] setNotifyValue:NO forCharacteristic:[[CBManager sharedManager] myCharacteristic]];
        [self logButtonAction:STOP_NOTIFY];
    }
}

/*!
 *  @method indicateButtonClicked:
 *
 *  @discussion Method to handle indicate button click
 *
 */
- (IBAction)indicateButtonClicked:(UIButton *)sender
{
    if (!sender.selected)
    {
        sender.selected = YES;
        [[[CBManager sharedManager] myPeripheral] setNotifyValue:YES forCharacteristic:[[CBManager sharedManager] myCharacteristic]];
        [self logButtonAction:START_INDICATE];
    }
    else
    {
        sender.selected = NO;
        [[[CBManager sharedManager] myPeripheral] setNotifyValue:NO forCharacteristic:[[CBManager sharedManager] myCharacteristic]];
        [self logButtonAction:STOP_INDICATE];
    }
}

/*!
 *  @method descriptorButtonClicked:
 *
 *  @discussion Method to handle descriptor button click
 *
 */

- (IBAction)descriptorButtonClicked:(UIButton *)sender
{
    [self performSegueWithIdentifier:DESCRIPTOR_LIST_SEGUE sender:self];
}

/*!
 *  @method updateUIWithHexValue: AndASCIIValue:
 *
 *  @discussion Method to update datafields
 *
 */
-(void) updateUIWithHexValue:(NSString *)hexValueString AndASCIIValue:(NSString *)ASCIIValueString
{
    _hexValueTextField.text = [[hexValueString stringByReplacingOccurrencesOfString:@"0x" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    _ASCIIValueTextField.text = ASCIIValueString;
    _dateValueLabel.text = [Utilities getCurrentDate];
    _timeValueLabel.text = [Utilities getCurrentTime];
    
 }

/*!
 *  @method writeDataForCharacteristic: WithData:
 *
 *  @discussion Method to write data to the device
 *
 */
-(void) writeDataForCharacteristic:(CBCharacteristic *)characteristic WithData:(NSData *)data completionHandler:(void(^) (BOOL success, NSError *error))handler
{
    characteristicWriteCompletionHandler = handler;
    if ((characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) != 0)
    {
        [[[CBManager sharedManager] myPeripheral] writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
        characteristicWriteCompletionHandler (YES,nil);
    }
    else
    {
        [[[CBManager sharedManager] myPeripheral] writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
}


/*!
 *  @method changeInDeviceOrientation:
 *
 *  @discussion Method to handle the UI change with device orientation in Ipad
 *
 */
-(void) changeInDeviceOrientation:(NSNotification *)notification{
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        [self initView];
        
        if (hexKeyboard){
            
            
            if ( hexKeyboard.orientation == UIDeviceOrientationFaceUp  && hexKeyboard.isPresent) {
                hexKeyboard.orientation = [UIDevice currentDevice].orientation;
            }
            
            if ([UIDevice currentDevice].orientation != UIDeviceOrientationFaceUp && hexKeyboard.orientation != [UIDevice currentDevice].orientation && hexKeyboard.isPresent) {
                
                [hexKeyboard changeViewFrameSizeToframe:CGRectMake(0, 0, self.view.frame.size.width, KEYBOARD_HEIGHT)];
                hexKeyboard.orientation = [UIDevice currentDevice].orientation;
            }
        }
    }
}

#pragma mark - CBCharacteristicManagerDelegate Methods


-(void) peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if ([characteristic.UUID isEqual:[[CBManager sharedManager] myCharacteristic].UUID])
    {
        // Show descriptor button only when descriptors exist for the characteristic
        if (characteristic.descriptors.count > 0)
        {
            [[CBManager sharedManager] setCharacteristicDescriptors:characteristic.descriptors];
            _descriptorButton.hidden = NO;
        }
    }
}


-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error == nil) {
        
        if (characteristic == [[CBManager sharedManager] myCharacteristic])
        {
            NSString *hexValue =[NSString stringWithFormat:@"0x%2@",characteristic.value];
            NSString *ASCIIValue = [Utilities convertCharacteristicValueToASCII:characteristic.value];
            [self updateUIWithHexValue:hexValue AndASCIIValue:ASCIIValue];
            
            if ([[CBManager sharedManager] myCharacteristic].isNotifying)
            {
                if (_indicateButton.selected)
                {
                    [self logOperation:INDICATE_RESPONSE forCharacteristic:characteristic withData:characteristic.value];
                }
                else if (_notifyButton.selected)
                {
                    [self logOperation:NOTIFY_RESPONSE forCharacteristic:characteristic withData:characteristic.value];
                }
            }
            else
            {
                [self logOperation:READ_RESPONSE forCharacteristic:characteristic withData:characteristic.value];
            }
        }
        else {
            if (characteristic.isNotifying) {
                [self logOperation:NOTIFY_RESPONSE forCharacteristic:characteristic withData:characteristic.value];
            }
        }
    }
}

-(void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if ([characteristic.UUID isEqual:[[CBManager sharedManager] myCharacteristic].UUID])
    {
        if (error == nil)
        {
            [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:[[CBManager sharedManager] myService].UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:[[CBManager sharedManager] myCharacteristic].UUID] descriptor:nil operation:[NSString stringWithFormat:@"%@- %@",WRITE_REQUEST_STATUS,WRITE_SUCCESS]];
            characteristicWriteCompletionHandler (YES,error);
        }
        else
        {
            [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:[[CBManager sharedManager] myService].UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:[[CBManager sharedManager] myCharacteristic].UUID] descriptor:nil operation:[NSString stringWithFormat:@"%@- %@%@",WRITE_REQUEST_STATUS,WRITE_ERROR,[error.userInfo objectForKey:NSLocalizedDescriptionKey]]];
           
            characteristicWriteCompletionHandler(NO,error);
        }
    }
}


#pragma mark - AlertView Delegate Methods

/*!
 *  @method alertView: clickedButtonAtIndex:
 *
 *  @discussion Method invoked when user click a button after enerting hex value
 *
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == HEX_ALERTVIEW_TAG)
    {
        if (buttonIndex == 1)
        {
            NSString *hexValue = [alertView textFieldAtIndex:0].text;
            NSMutableData *dataToWrite = [Utilities dataFromHexString:[hexValue stringByReplacingOccurrencesOfString:@"0x" withString:@""]];
            
            if (dataToWrite.length) {
                NSString *ASCIIValue = [Utilities convertCharacteristicValueToASCII:dataToWrite];
                
                // Write data to the device
                
                [self logOperation:WRITE_REQUEST forCharacteristic:[[CBManager sharedManager] myCharacteristic] withData:dataToWrite];
                [self writeDataForCharacteristic:[[CBManager sharedManager] myCharacteristic] WithData:dataToWrite completionHandler:^(BOOL success, NSError *error) {
                    
                    if (success)
                    {
                        [self updateUIWithHexValue:hexValue AndASCIIValue:ASCIIValue];
                    }
                    else
                    {
                        [self updateUIWithHexValue:@"" AndASCIIValue:@""];
                        [Utilities alert:APP_NAME Message:[NSString stringWithFormat:@"Error occured in writing data.\n Error:%@\n Please try again.",[[error userInfo] valueForKey:NSLocalizedDescriptionKey]]];
                    }
                }];
            }
        }
        hexKeyboard.isPresent = NO;
    }
    else if (alertView.tag == ASCII_ALERTVIEW_TAG){
        
        if (buttonIndex == 1) {
            
            NSString *ASCIIValue = [alertView textFieldAtIndex:0].text;
            NSString *hexValue = [Utilities convertToHexFromASCII:ASCIIValue];
            NSMutableData *dataToWrite = [Utilities dataFromHexString:[hexValue stringByReplacingOccurrencesOfString:@"0x" withString:@""]];
            
            if (dataToWrite.length) {
                // Write data to the device
                
                [self logOperation:WRITE_REQUEST forCharacteristic:[[CBManager sharedManager] myCharacteristic] withData:dataToWrite];
                [self writeDataForCharacteristic:[[CBManager sharedManager] myCharacteristic] WithData:dataToWrite completionHandler:^(BOOL success, NSError *error) {
                    
                    if (success)
                    {
                        [self updateUIWithHexValue:hexValue AndASCIIValue:ASCIIValue];
                    }
                    else
                    {
                        [self updateUIWithHexValue:@"" AndASCIIValue:@""];
                        [Utilities alert:APP_NAME Message:[NSString stringWithFormat:@"Error occured in writing data.\n Error:%@\n Please try again.",[[error userInfo] valueForKey:NSLocalizedDescriptionKey]]];
                    }
                }];
            }
        }
    }
}


#pragma mark - Segue Methods


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:DESCRIPTOR_LIST_SEGUE]) {
        GATTDBDescriptorListViewController * listVC = segue.destinationViewController;
        listVC.serviceName = [ResourceHandler getServiceNameForUUID:[[CBManager sharedManager] myService].UUID];
        listVC.characteristicName = [ResourceHandler getCharacteristicNameForUUID:[[CBManager sharedManager] myCharacteristic].UUID];
    }
}

#pragma mark - Utility Methods

/*!
 *  @method addDoneButton:
 *
 *  @discussion Method to add a done button on top of the keyboard when displayed
 *
 */

- (void)addDoneButton {
    UIToolbar* keyboardToolbar = [[UIToolbar alloc] init];
    [keyboardToolbar sizeToFit];
    UIBarButtonItem * flexBarButton= [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                      target:nil action:nil];
    UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self action:@selector(doneButtonPressed)];
    keyboardToolbar.items = @[flexBarButton, doneBarButton];
    hexAlertTextField.inputAccessoryView = keyboardToolbar;
}

/*!
 *  @method doneButtonPressed
 *
 *  @discussion Method to get notified when the custom done button on top of keyboard is tapped
 *
 */

- (void)doneButtonPressed {
    [hexAlertTextField resignFirstResponder];
    [self.view endEditing:YES];
}

/*!
 *  @method logButtonAction:
 *
 *  @discussion Method to log details of various operations
 *
 */
-(void) logButtonAction:(NSString *)action
{
    [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:[[CBManager sharedManager] myService].UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:[[CBManager sharedManager] myCharacteristic].UUID] descriptor:nil operation:action];
}

/*!
 *  @method logOperation: forCharacteristic: andData:
 *
 *  @discussion Method to log characteristic value
 *
 */
-(void) logOperation:(NSString *)operation forCharacteristic:(CBCharacteristic *)characteristic withData:(NSData *)data
{
    [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:characteristic.service.UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:characteristic.UUID] descriptor:nil operation:[NSString stringWithFormat:@"%@%@ %@",operation,DATA_SEPERATOR,[Utilities convertDataToLoggerFormat:data]]];
}


#pragma mark - UITextfield delegate


-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    if (!([[CBManager sharedManager] myCharacteristic].properties & CBCharacteristicPropertyWrite || [[CBManager sharedManager] myCharacteristic].properties & CBCharacteristicPropertyWriteWithoutResponse)) {
        return NO;
    }
    
    if (textField.tag == ASCIIT_TEXFIELD_TAG) {
        [self showASCIIKeyboard];
        return NO;
    }else if (textField.tag == HEX_TEXTFIELD_TAG) {
        [self showHexKeyboard];
        return NO;
    }
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [textField resignFirstResponder];
    return NO;
}


@end
