//
//  MRHexKeyboard.m
//
//  Created by Mikk Rätsep on 02/10/13.
//  Copyright (c) 2013 Mikk Rätsep. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "MRHexKeyboard.h"

const CGFloat kKeyboardHeight = 305.0f;

static UIColor *sGrayColour = nil;

@interface MRHexKeyboard () {
    __weak UITextField *_textField;
}

- (void)createButtons;
- (void)makeButtonWithRect:(CGRect)rect title:(NSString *)title grayBackground:(BOOL)grayBackground;

- (NSString *)buttonTitleForNumber:(NSInteger)num;
- (CGPoint)buttonOriginPointForNumber:(NSInteger)num;

- (void)changeButtonBackgroundColourForHighlight:(UIButton *)button;
- (void)changeTextFieldText:(UIButton *)button;

@end

@implementation MRHexKeyboard

- (MRHexKeyboard *)initWithTextField:(UITextField *)textField
{
    self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, kKeyboardHeight)];

    if (self) {
        _textField = textField;

        sGrayColour = [UIColor lightTextColor];

        self.backgroundColor = [UIColor lightGrayColor];

        [self createButtons];
    }
    
    return self;
}

- (void)createButtons
{
    CGRect rect = CGRectMake(0.0f, 0.0f, (floor(self.bounds.size.width / 3.0f) + 0.3f), (((kKeyboardHeight - 5.0f) / 6.0f) + 0.3f));

    /* Makes the numerical buttons */
    for (NSInteger num = 1; num <= 15; num++) {
        rect.origin = [self buttonOriginPointForNumber:num];

        [self makeButtonWithRect:rect title:[self buttonTitleForNumber:num] grayBackground:NO];
    }

    /* Makes the '0x' button */
    rect.origin = [self buttonOriginPointForNumber:16];

    [self makeButtonWithRect:rect title:@"0x" grayBackground:YES];

    /* Makes the '0' button */
    rect.origin = [self buttonOriginPointForNumber:17];

    [self makeButtonWithRect:rect title:@"0" grayBackground:NO];

    /* Makes the 'delete' button */
    rect.origin = [self buttonOriginPointForNumber:18];

    UIButton *button = [[UIButton alloc] initWithFrame:rect];

    button.backgroundColor = sGrayColour;
    [button setImage:[UIImage imageNamed:@"deleteButton"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(changeButtonBackgroundColourForHighlight:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(changeButtonBackgroundColourForHighlight:) forControlEvents:UIControlEventTouchDragEnter];
    [button addTarget:self action:@selector(changeButtonBackgroundColourForHighlight:) forControlEvents:UIControlEventTouchDragExit];
    [button addTarget:self action:@selector(changeTextFieldText:) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:button];
}

- (void)makeButtonWithRect:(CGRect)rect title:(NSString *)title grayBackground:(BOOL)grayBackground
{
    UIButton *button = [[UIButton alloc] initWithFrame:rect];
    CGFloat fontSize = 25.0f;

    if (![[NSCharacterSet decimalDigitCharacterSet] isSupersetOfSet:[NSCharacterSet characterSetWithCharactersInString:title]]) {
        fontSize = 20.0f;
    }

    button.backgroundColor = (grayBackground) ? sGrayColour : [UIColor whiteColor];
    button.titleLabel.font = [UIFont systemFontOfSize:fontSize];

    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:@selector(changeButtonBackgroundColourForHighlight:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(changeButtonBackgroundColourForHighlight:) forControlEvents:UIControlEventTouchDragEnter];
    [button addTarget:self action:@selector(changeButtonBackgroundColourForHighlight:) forControlEvents:UIControlEventTouchDragExit];
    [button addTarget:self action:@selector(changeTextFieldText:) forControlEvents:UIControlEventTouchUpInside];

    [self addSubview:button];
}

- (NSString *)buttonTitleForNumber:(NSInteger)num
{
    NSString *str = [NSString stringWithFormat:@"%ld", (long)num];

    if (num <= 15) {
        if (num >= 10) {
            str = @[@"A", @"B", @"C", @"D", @"E", @"F"][num - 10];
        }
    }
    else {
        str = @"F#%K";
    }

    return str;
}

- (CGPoint)buttonOriginPointForNumber:(NSInteger)num
{
    CGPoint point = CGPointMake(0.0f, 0.0f);

    if ((num % 3) == 2) { /* 2nd button in the row */
        point.x = ceil(self.bounds.size.width / 3.0f);
    }
    else if ((num % 3) == 0) { /* 3rd button in the row */
        point.x = ceil((self.bounds.size.width / 3.0f * 2.0f));
    }

    if (num > 3) { /* The row multiplied by row's height */
        point.y = floor((num - 1) / 3.0f) * (kKeyboardHeight / 6.0f);
    }

    return point;
}

- (void)changeButtonBackgroundColourForHighlight:(UIButton *)button
{
    UIColor *newColour = sGrayColour;

    if ([button.backgroundColor isEqual:sGrayColour]) {
        newColour = [UIColor whiteColor];
    }

    button.backgroundColor = newColour;
}

- (void)changeTextFieldText:(UIButton *)button
{
    if (_textField) {
        NSMutableString *string = [NSMutableString stringWithString:_textField.text];

        if (button.titleLabel.text) {
            if ([button.titleLabel.text isEqualToString:@"0x"]) {
                if (string.length == 0) {
                    [string appendString:@"0x"];
                }
                else {
                    [string appendString:@" 0x"];
                }
            }
            else if (string.length == 0) {
                [string appendFormat:@"0x%@", button.titleLabel.text];
            }
            else {
                if (string.length > 2) {
                    NSString *lastTwoChars = [string substringFromIndex:(string.length - 2)];

                    if ([lastTwoChars rangeOfString:@"x"].location == NSNotFound) {
                        [string appendFormat:@" 0x%@", button.titleLabel.text];
                    }
                    else {
                        [string appendString:button.titleLabel.text];
                    }
                }
                else {
                    [string appendString:button.titleLabel.text];
                }
            }
        }
        else if (_textField.text.length > 0) {
            NSRange deleteRange;
            NSString *lastChar = [string substringFromIndex:(string.length - 1)];

            if ([lastChar isEqualToString:@"x"]) {
                if (string.length > 2) {
                    deleteRange = NSMakeRange((string.length - 3), 3);
                }
                else {
                    deleteRange = NSMakeRange((string.length - 2), 2);
                }
            }
            else {
                deleteRange = NSMakeRange((string.length - 1), 1);
            }

            [string deleteCharactersInRange:deleteRange];
        }

        _textField.text = string;
    }

    [self changeButtonBackgroundColourForHighlight:button];
}


-(void) changeViewFrameSizeToframe:(CGRect)newFrame
{
    self.frame = newFrame;
    
    for (UIView *view in self.subviews)
    {
        [view removeFromSuperview];
    }
    
    [self createButtons];
}

@end
