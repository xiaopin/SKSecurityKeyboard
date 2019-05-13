//
//  SKSecurityKeyboard.m
//  https://github.com/xiaopin/SKSecurityKeyboard.git
//
//  Created by NHope on 2019/5/10.
//  Copyright © 2019 xiaopin. All rights reserved.
//

#import "SKSecurityKeyboard.h"
#import <objc/message.h>
#import <AudioToolbox/AudioToolbox.h>

#define DIGIT_BUTTON_TAG    9
#define DELETE_BUTTON_TAG   11
#define TOOLBAR_HEIGHT      40.0

/// 将 UITextRange 转成 NSRange
NSRange sk_NSTextRange2NSRange(UITextField *textField)
{
    UITextPosition *start = textField.selectedTextRange.start;
    UITextPosition *end = textField.selectedTextRange.end;
    const NSInteger location = [textField offsetFromPosition:textField.beginningOfDocument toPosition:start];
    const NSInteger length = [textField offsetFromPosition:start toPosition:end];
    return NSMakeRange(location, length);
}

UIImage* sk_imageResourceFromName(NSString *name)
{
    NSString *path = [@"SKSecurityKeyboard.bundle" stringByAppendingPathComponent:name];
    return [UIImage imageNamed:path];
}

UIImage* sk_UIColor2UIImage(UIColor *color, CGSize size)
{
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, (CGRect){CGPointZero, size});
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

UIKIT_STATIC_INLINE UIColor* sk_rgb(CGFloat r, CGFloat g, CGFloat b)
{
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
}

#pragma mark -

@interface SKSecurityKeyboardButton : UIButton

- (void)clearStyle;

@end

@implementation SKSecurityKeyboardButton

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.layer.mask = [CAShapeLayer layer];
        self.backgroundColor = [UIColor whiteColor];
        [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont systemFontOfSize:24.0 weight:(UIFontWeightLight + UIFontWeightRegular)/2];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.layer.mask) {
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(8.0, 8.0)];
        CAShapeLayer *shapeLayer = (CAShapeLayer *)self.layer.mask;
        shapeLayer.path = [bezierPath CGPath];
    }
}

- (void)clearStyle {
    self.layer.mask = nil;
    self.backgroundColor = [UIColor clearColor];
    [self setBackgroundImage:nil forState:UIControlStateHighlighted];
}

@end


#pragma mark -

@interface SKSecurityKeyboard ()
{
    UIToolbar *_toolbar;
    UIView *_contentView;
    NSArray<NSString *> *_numbers;
    dispatch_source_t _timer;
    __weak id<UITextInput> _inputSource;
}
@end

@implementation SKSecurityKeyboard

#pragma mark Lifecycle

- (instancetype)initWithInputSource:(id<UITextInput>)inputSource {
    return [self initWithInputSource:inputSource keyboardType:SKSecurityKeyboardTypeNumber];
}

- (instancetype)initWithInputSource:(id<UITextInput>)inputSource keyboardType:(SKSecurityKeyboardType)keyboardType {
    NSAssert(inputSource
             && ([inputSource isKindOfClass:UITextField.class] || [inputSource isKindOfClass:UITextView.class]),
             @"`inputSource` must be UITextField/UITextView or its subclass.");
    if (self = [super initWithFrame:CGRectZero]) {
        UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonAction:)];
        _toolbar = [[UIToolbar alloc] init];
        [_toolbar setItems:@[spaceItem, doneItem] animated:NO];
        _toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_toolbar];
        [_toolbar.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
        [_toolbar.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
        [_toolbar.widthAnchor constraintEqualToAnchor:self.widthAnchor].active = YES;
        [_toolbar.heightAnchor constraintEqualToConstant:TOOLBAR_HEIGHT].active = YES;
        
        _contentView = [[UIView alloc] init];
        _contentView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_contentView];
        if (@available(iOS 11.0, *)) {
            [_contentView.bottomAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.bottomAnchor].active = YES;
            [_contentView.leadingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.leadingAnchor].active = YES;
            [_contentView.trailingAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.trailingAnchor].active = YES;
        } else {
            [_contentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
            [_contentView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
            [_contentView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
        }
        [_contentView.topAnchor constraintEqualToAnchor:_toolbar.bottomAnchor].active = YES;

        _inputSource = inputSource;
        _enabledInputAccessoryView = YES;
        _enabledKeyboardSound = YES;
        [self setKeyboardType:keyboardType];
        
        NSNotificationName name = ([inputSource isKindOfClass:UITextField.class]) ? UITextFieldTextDidBeginEditingNotification : UITextViewTextDidBeginEditingNotification;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputSourceDidBeginEditingNotification:) name:name object:inputSource];
    }
    return self;
}

- (void)dealloc {
    if (_timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidBeginEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidBeginEditingNotification object:nil];
}

#pragma mark Actions

- (void)buttonAction:(SKSecurityKeyboardButton *)sender {
    const NSInteger index = sender.tag;
    NSString *text = [self getTextWithIndex:index];
    if (text == nil && index != DELETE_BUTTON_TAG) return;
    // Check if it should change
    if ([_inputSource isKindOfClass:UITextField.class]) {
        UITextField *textField = (UITextField *)_inputSource;
        if (textField.delegate && [textField.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
            NSRange range = sk_NSTextRange2NSRange(textField);
            if (index == DELETE_BUTTON_TAG) {
                if (range.location == 0) return;
                range.location = MAX(0, range.location-1);
                range.length = MAX(1, range.length);
            }
            BOOL flag = [textField.delegate textField:textField shouldChangeCharactersInRange:range replacementString:text];
            if (!flag) {
                return;
            }
        }
    } else if ([_inputSource isKindOfClass:UITextView.class]) {
        UITextView *textView = (UITextView *)_inputSource;
        if (textView.delegate && [textView.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
            BOOL flag = [textView.delegate textView:textView shouldChangeTextInRange:textView.selectedRange replacementText:text];
            if (!flag) {
                return;
            }
        }
    } else {
        NSAssert(NO, nil);
    }
    // Apply changes
    if (index == DELETE_BUTTON_TAG) {
        [_inputSource deleteBackward];
    } else {
        [_inputSource insertText:text];
    }
    // Key sound
    if (_enabledKeyboardSound) {
        // http://iphonedevwiki.net/index.php/AudioServices
        AudioServicesPlaySystemSound(1104);
    }
}

- (void)deleteButtonLongPressGestureRecognizerAction:(UILongPressGestureRecognizer *)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            if (_inputSource.hasText) {
                __weak __typeof(self) weakSelf = self;
                __weak SKSecurityKeyboardButton *weakButton = (SKSecurityKeyboardButton *)sender.view;
                _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
                dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, NSEC_PER_MSEC * 100, 0);
                dispatch_source_set_event_handler(_timer, ^{
                    __strong __typeof(weakSelf) strongSelf = weakSelf;
                    __strong __typeof(weakButton) strongButton = weakButton;
                    if (strongSelf == nil || strongButton == nil) return;
                    if ([strongSelf->_inputSource hasText]) {
                        [strongButton setHighlighted:YES];
                        [strongSelf buttonAction:strongButton];
                        return;
                    }
                    dispatch_source_cancel(strongSelf->_timer);
                    strongSelf->_timer = nil;
                    [strongButton setHighlighted:NO];
                });
                dispatch_resume(_timer);
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            if (_timer) {
                dispatch_source_cancel(_timer);
                _timer = nil;
            }
            SKSecurityKeyboardButton *button = (SKSecurityKeyboardButton *)sender.view;
            [button setHighlighted:NO];
            break;
        }
        default:
            break;
    }
}

- (void)doneButtonAction:(UIBarButtonItem *)sender {
    [(UIResponder *)_inputSource resignFirstResponder];
}

- (void)inputSourceDidBeginEditingNotification:(NSNotification *)sender {
    switch (self.keyboardType) {
        case SKSecurityKeyboardTypeNumberRandom:
        case SKSecurityKeyboardTypeDecimalRandom:
            [self resortNumbers];
            break;
        default:
            break;
    }
}

#pragma mark Private

- (void)updateKeyboardButtons {
    // Reuse keyboard buttons
    if (_contentView.subviews.count) {
        UIStackView *rowStackView = (UIStackView *)_contentView.subviews.firstObject;
        for (UIStackView *columnStackView in rowStackView.arrangedSubviews) {
            for (SKSecurityKeyboardButton *button in columnStackView.arrangedSubviews) {
                const NSInteger index = button.tag;
                NSString *text = [self getTextWithIndex:index];
                [button setTitle:text forState:UIControlStateNormal];
            }
        }
        return;
    }
    
    // Create keyboared buttons for the first time
    const CGFloat spacing = 8.0;
    UIImage *highlightImage = sk_UIColor2UIImage(sk_rgb(183, 194, 207), CGSizeMake(1.0, 1.0));
    UIStackView *rowStackView = [[UIStackView alloc] init];
    rowStackView.axis = UILayoutConstraintAxisVertical;
    rowStackView.distribution = UIStackViewDistributionFillEqually;
    rowStackView.spacing = spacing;
    
    for (int row=0; row<4; row++) {
        UIStackView *columnStackView = [[UIStackView alloc] init];
        columnStackView.axis = UILayoutConstraintAxisHorizontal;
        columnStackView.distribution = UIStackViewDistributionFillEqually;
        columnStackView.spacing = spacing;
        for (int column=0; column<3; column++) {
            const int index = row * 3 + column;
            SKSecurityKeyboardButton *button = [SKSecurityKeyboardButton buttonWithType:UIButtonTypeCustom];
            button.tag = index;
            [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
            [button setTitle:[self getTextWithIndex:index] forState:UIControlStateNormal];
            [button setBackgroundImage:highlightImage forState:UIControlStateHighlighted];
            if (index == DIGIT_BUTTON_TAG || index == DELETE_BUTTON_TAG) {
                [button clearStyle];
                if (index == DELETE_BUTTON_TAG) {
                    [button setImage:sk_imageResourceFromName(@"delete") forState:UIControlStateNormal];
                    [button setImage:sk_imageResourceFromName(@"delete-highlight") forState:UIControlStateHighlighted];
                    // Long press to delete text
                    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(deleteButtonLongPressGestureRecognizerAction:)];
                    [button addGestureRecognizer:longPressGesture];
                }
            }
            [columnStackView addArrangedSubview:button];
        }
        [rowStackView addArrangedSubview:columnStackView];
    }
    
    [_contentView addSubview:rowStackView];
    [rowStackView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [rowStackView.topAnchor constraintEqualToAnchor:_contentView.topAnchor constant:spacing].active = YES;
    [rowStackView.bottomAnchor constraintEqualToAnchor:_contentView.bottomAnchor constant:-spacing].active = YES;
    [rowStackView.leadingAnchor constraintEqualToAnchor:_contentView.leadingAnchor constant:spacing].active = YES;
    [rowStackView.trailingAnchor constraintEqualToAnchor:_contentView.trailingAnchor constant:-spacing].active = YES;
}

- (void)resortNumbers {
    _numbers = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"0"];
    if (self.keyboardType == SKSecurityKeyboardTypeNumberRandom || self.keyboardType == SKSecurityKeyboardTypeDecimalRandom) {
        NSMutableArray *array = [NSMutableArray arrayWithArray:_numbers];
        for (int i=0; i<array.count; i++) {
            NSUInteger index = arc4random() % array.count;
            [array exchangeObjectAtIndex:i withObjectAtIndex:index];
        }
        _numbers = [NSArray arrayWithArray:array];
    }
    [self updateKeyboardButtons];
}

- (NSString *)getTextWithIndex:(NSInteger)index {
    NSString *text = nil;
    switch (index) {
        case DIGIT_BUTTON_TAG:
            if (self.keyboardType == SKSecurityKeyboardTypeDecimal || self.keyboardType == SKSecurityKeyboardTypeDecimalRandom) {
                text = @".";
            } else if (self.keyboardType == SKSecurityKeyboardTypeIDCard) {
                text = @"X";
            }
            break;
        case DELETE_BUTTON_TAG:
            text = @"";
            break;
        default:
            text = (index < _numbers.count) ? _numbers[index] : _numbers.lastObject;
            break;
    }
    return text;
}

#pragma mark setter & getter

- (void)setKeyboardType:(SKSecurityKeyboardType)keyboardType {
    _keyboardType = keyboardType;
    [self resortNumbers];
}

- (void)setEnabledInputAccessoryView:(BOOL)enabledInputAccessoryView {
    if (_enabledInputAccessoryView == enabledInputAccessoryView) return;
    _enabledInputAccessoryView = enabledInputAccessoryView;
    for (NSLayoutConstraint *constraint in self.constraints) {
        if (constraint.firstItem == _contentView && constraint.firstAttribute == NSLayoutAttributeTop
            && constraint.secondItem == _toolbar && constraint.secondAttribute == NSLayoutAttributeBottom) {
            constraint.constant = enabledInputAccessoryView ? 0.0 : -TOOLBAR_HEIGHT;
            _toolbar.hidden = !enabledInputAccessoryView;
            break;
        }
    }
}

- (void)setFrame:(CGRect)frame {
    // TODO:
    UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    BOOL isPortrait = UIInterfaceOrientationIsPortrait(statusBarOrientation);
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = isPortrait ? 300.0 : 240.0;
    frame.size = CGSizeMake(width, height);
    [super setFrame:frame];
}

@end


#pragma mark -

@implementation UITextField (SKSecurityKeyboard)

- (void)setEnabledSecurityKeyboard:(BOOL)enabledSecurityKeyboard {
    NSAssert(self.inputView == nil || [self.inputView isKindOfClass:SKSecurityKeyboard.class], @"`inputView` already exists and is not an SKSecurityKeyboard class");
    if (self.isEnabledSecurityKeyboard == enabledSecurityKeyboard) return;
    if (enabledSecurityKeyboard) {
        self.inputView = [[SKSecurityKeyboard alloc] initWithInputSource:self];
    } else {
        self.inputView = nil;
    }
    objc_setAssociatedObject(self, @selector(isEnabledSecurityKeyboard), @(enabledSecurityKeyboard), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isEnabledSecurityKeyboard {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (SKSecurityKeyboard *)securityKeyboard {
    if (self.inputView && [self.inputView isKindOfClass:SKSecurityKeyboard.class]) {
        return (SKSecurityKeyboard *)self.inputView;
    }
    return nil;
}

@end


@implementation UITextView (SKSecurityKeyboard)

- (void)setEnabledSecurityKeyboard:(BOOL)enabledSecurityKeyboard {
    NSAssert(self.inputView == nil || [self.inputView isKindOfClass:SKSecurityKeyboard.class], @"`inputView` already exists and is not an SKSecurityKeyboard class");
    if (self.isEnabledSecurityKeyboard == enabledSecurityKeyboard) return;
    if (enabledSecurityKeyboard) {
        self.inputView = [[SKSecurityKeyboard alloc] initWithInputSource:self];
    } else {
        self.inputView = nil;
    }
    objc_setAssociatedObject(self, @selector(isEnabledSecurityKeyboard), @(enabledSecurityKeyboard), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isEnabledSecurityKeyboard {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (SKSecurityKeyboard *)securityKeyboard {
    if (self.inputView && [self.inputView isKindOfClass:SKSecurityKeyboard.class]) {
        return (SKSecurityKeyboard *)self.inputView;
    }
    return nil;
}

@end
