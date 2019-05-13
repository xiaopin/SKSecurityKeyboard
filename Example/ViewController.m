//
//  ViewController.m
//  Example
//
//  Created by NHope on 2019/5/10.
//  Copyright © 2019 xiaopin. All rights reserved.
//

#import "ViewController.h"
#import "SKSecurityKeyboard.h"

@interface ViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *numberTextField;
@property (weak, nonatomic) IBOutlet UITextField *numberRandomTextField;
@property (weak, nonatomic) IBOutlet UITextField *digitTextField;
@property (weak, nonatomic) IBOutlet UITextField *digitRandomTextField;
@property (weak, nonatomic) IBOutlet UITextField *idcardTextField;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.numberRandomTextField.securityKeyboard.keyboardType = SKSecurityKeyboardTypeNumberRandom;
    self.digitTextField.securityKeyboard.keyboardType = SKSecurityKeyboardTypeDecimal;
    self.digitRandomTextField.securityKeyboard.keyboardType = SKSecurityKeyboardTypeDecimalRandom;
    self.idcardTextField.securityKeyboard.keyboardType = SKSecurityKeyboardTypeIDCard;
    self.idcardTextField.securityKeyboard.enabledInputAccessoryView = NO;
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    NSLog(@"%s", __FUNCTION__);
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    NSLog(@"%s", __FUNCTION__);
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    NSLog(@"%s", __FUNCTION__);
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSLog(@"%s", __FUNCTION__);
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    NSLog(@"%s", __FUNCTION__);
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSLog(@"%s", __FUNCTION__);
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"%@, %@", NSStringFromRange(range), string);
    return YES;
}

@end
