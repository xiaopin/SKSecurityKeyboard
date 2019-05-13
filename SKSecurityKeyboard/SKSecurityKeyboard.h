//
//  SKSecurityKeyboard.h
//  https://github.com/xiaopin/SKSecurityKeyboard.git
//
//  Created by NHope on 2019/5/10.
//  Copyright © 2019 xiaopin. All rights reserved.
//

#import <UIKit/UIKit.h>

/// 键盘类型
NS_SWIFT_NAME(SecurityKeyboardType)
typedef NS_ENUM(NSInteger, SKSecurityKeyboardType) {
    SKSecurityKeyboardTypeNumber,           // 数字键盘
    SKSecurityKeyboardTypeNumberRandom,     // 随机数字键盘
    SKSecurityKeyboardTypeDecimal,          // 带小数点的数字键盘
    SKSecurityKeyboardTypeDecimalRandom,    // 带小数点的随机数字键盘
    SKSecurityKeyboardTypeIDCard,           // 身份证数字键盘
};


NS_ASSUME_NONNULL_BEGIN

/// 安全键盘
NS_SWIFT_NAME(SecurityKeyboard)
NS_CLASS_AVAILABLE_IOS(9_0) @interface SKSecurityKeyboard : UIView

/// 键盘类型, 默认`SKSecurityKeyboardTypeNumber`
@property (nonatomic, assign) SKSecurityKeyboardType keyboardType;
/// 是否显示自带的辅助工具条, 默认`YES`
@property (nonatomic, assign, getter=isEnabledInputAccessoryView) BOOL enabledInputAccessoryView;
/// 是否启用按键音, 默认`YES`, 需要关闭手机的静音模式才会有声音
@property (nonatomic, assign, getter=isEnabledKeyboardSound) BOOL enabledKeyboardSound;

/**
 初始化

 @param inputSource 输入源(必须是UITextField/UITextView或其子类)
 @return SKSecurityKeyboard
 */
- (instancetype)initWithInputSource:(id<UITextInput>)inputSource;

/**
 初始化

 @param inputSource 输入源(必须是UITextField/UITextView或其子类)
 @param keyboardType 键盘类型
 @return SKSecurityKeyboard
 */
- (instancetype)initWithInputSource:(id<UITextInput>)inputSource keyboardType:(SKSecurityKeyboardType)keyboardType;


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end



#pragma mark - Category

@interface UITextField (SKSecurityKeyboard)

/// 是否启用安全键盘
@property (nonatomic, assign, getter=isEnabledSecurityKeyboard) IBInspectable BOOL enabledSecurityKeyboard;
/// 键盘
@property (nonatomic, strong, readonly, nullable) SKSecurityKeyboard *securityKeyboard;

@end


@interface UITextView (SKSecurityKeyboard)

/// 是否启用安全键盘
@property (nonatomic, assign, getter=isEnabledSecurityKeyboard) IBInspectable BOOL enabledSecurityKeyboard;
/// 键盘
@property (nonatomic, strong, readonly, nullable) SKSecurityKeyboard *securityKeyboard;

@end


NS_ASSUME_NONNULL_END
