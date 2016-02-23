//
//  MMNumberKeyboard.m
//  MMNumberKeyboard
//
//  Created by Matías Martínez on 12/10/15.
//  Copyright © 2015 Matías Martínez. All rights reserved.
//

#import "MMCalculatorProcessor.h"
#import "MMNumberKeyboard.h"

@interface MMNumberKeyboard () <UIInputViewAudioFeedback>

@property(strong, nonatomic) NSDictionary *buttonDictionary;
@property(strong, nonatomic) NSMutableArray *separatorViews;
@property(strong, nonatomic) NSLocale *locale;

@property(copy, nonatomic) dispatch_block_t specialKeyHandler;

@end

@interface _MMNumberKeyboardButton : UIButton

+ (_MMNumberKeyboardButton *)keyboardButtonWithStyle:(MMNumberKeyboardButtonStyle)style;

// The style of the keyboard button.
@property(assign, nonatomic) MMNumberKeyboardButtonStyle style;

// Notes the continuous press time interval, then adds the target/action to the
// UIControlEventValueChanged event.
- (void)addTarget:(id)target action:(SEL)action forContinuousPressWithTimeInterval:(NSTimeInterval)timeInterval;

@end

static __weak id currentFirstResponder;

@implementation UIResponder (FirstResponder)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-repeated-use-of-weak"
+ (id)MM_currentFirstResponder {
    currentFirstResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(MM_findFirstResponder:) to:nil from:nil forEvent:nil];
    return currentFirstResponder;
}
#pragma clang diagnostic pop

- (void)MM_findFirstResponder:(id)sender {
    currentFirstResponder = self;
}

@end

@implementation MMNumberKeyboard

static const CGFloat MMNumberKeyboardRowHeight = 55.0f;
static const CGFloat MMNumberKeyboardPadBorder = 7.0f;
static const CGFloat MMNumberKeyboardPadSpacing = 8.0f;

#define UIKitLocalizedString(key) [[NSBundle bundleWithIdentifier:@"com.apple.UIKit"] localizedStringForKey:key value:@"" table:nil]

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame inputViewStyle:UIInputViewStyleKeyboard];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame inputViewStyle:(UIInputViewStyle)inputViewStyle {
    self = [super initWithFrame:frame inputViewStyle:inputViewStyle];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame inputViewStyle:(UIInputViewStyle)inputViewStyle locale:(NSLocale *)locale {
    self = [super initWithFrame:frame inputViewStyle:inputViewStyle];
    if (self) {
        self.locale = locale;
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit {
    NSMutableDictionary *buttonDictionary = [NSMutableDictionary dictionary];

    const NSInteger numberMin = MMNumberKeyboardButtonNumberMin;
    const NSInteger numberMax = MMNumberKeyboardButtonNumberMax;

    UIFont *buttonFont;
    if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)]) {
        buttonFont = [UIFont systemFontOfSize:28.0f weight:UIFontWeightLight];
    } else {
        buttonFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:28.0f];
    }

    UIFont *doneButtonFont = [UIFont systemFontOfSize:17.0f];

    for (MMNumberKeyboardButton key = numberMin; key < numberMax; key++) {
        UIButton *button = [_MMNumberKeyboardButton keyboardButtonWithStyle:MMNumberKeyboardButtonStyleWhite];
        NSString *title = @(key - numberMin).stringValue;

        [button setTitle:title forState:UIControlStateNormal];
        [button.titleLabel setFont:buttonFont];

        [buttonDictionary setObject:button forKey:@(key)];
    }

    UIImage *backspaceImage = [self.class _keyboardImageNamed:@"MMNumberKeyboardDeleteKey.png"];
    UIImage *dismissImage = [self.class _keyboardImageNamed:@"MMNumberKeyboardDismissKey.png"];

    UIButton *backspaceButton = [_MMNumberKeyboardButton keyboardButtonWithStyle:MMNumberKeyboardButtonStyleGray];
    [backspaceButton setImage:[backspaceImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];

    [(_MMNumberKeyboardButton *)backspaceButton addTarget:self action:@selector(_backspaceRepeat:) forContinuousPressWithTimeInterval:0.15f];

    [buttonDictionary setObject:backspaceButton forKey:@(MMNumberKeyboardButtonBackspace)];

    UIButton *specialButton = [_MMNumberKeyboardButton keyboardButtonWithStyle:MMNumberKeyboardButtonStyleGray];

    [buttonDictionary setObject:specialButton forKey:@(MMNumberKeyboardButtonSpecial)];

    UIButton *doneButton = [_MMNumberKeyboardButton keyboardButtonWithStyle:MMNumberKeyboardButtonStyleDone];
    [doneButton.titleLabel setFont:doneButtonFont];
    [doneButton setTitle:UIKitLocalizedString(@"Done") forState:UIControlStateNormal];

    [buttonDictionary setObject:doneButton forKey:@(MMNumberKeyboardButtonDone)];

    UIButton *decimalPointButton = [_MMNumberKeyboardButton keyboardButtonWithStyle:MMNumberKeyboardButtonStyleGray];

    NSLocale *locale = self.locale ?: [NSLocale currentLocale];
    NSString *decimalSeparator = [locale objectForKey:NSLocaleDecimalSeparator];
    [decimalPointButton setTitle:decimalSeparator ?: @"." forState:UIControlStateNormal];

    [buttonDictionary setObject:decimalPointButton forKey:@(MMNumberKeyboardButtonDecimalPoint)];

    UIButton *addButton = [_MMNumberKeyboardButton keyboardButtonWithStyle:MMNumberKeyboardButtonStyleGray];
    [addButton setTitle:@"+" forState:UIControlStateNormal];
    [addButton.titleLabel setFont:buttonFont];
    [buttonDictionary setObject:addButton forKey:@(MMNumberKeyboardButtonAdd)];

    UIButton *minusButton = [_MMNumberKeyboardButton keyboardButtonWithStyle:MMNumberKeyboardButtonStyleGray];
    [minusButton setTitle:@"-" forState:UIControlStateNormal];
    [minusButton.titleLabel setFont:buttonFont];
    [buttonDictionary setObject:minusButton forKey:@(MMNumberKeyboardButtonMinus)];

    UIButton *multiplyButton = [_MMNumberKeyboardButton keyboardButtonWithStyle:MMNumberKeyboardButtonStyleGray];
    [multiplyButton setTitle:@"×" forState:UIControlStateNormal];
    [multiplyButton.titleLabel setFont:buttonFont];
    [buttonDictionary setObject:multiplyButton forKey:@(MMNumberKeyboardButtonMultiply)];

    UIButton *divideButton = [_MMNumberKeyboardButton keyboardButtonWithStyle:MMNumberKeyboardButtonStyleGray];
    [divideButton setTitle:@"÷" forState:UIControlStateNormal];
    [divideButton.titleLabel setFont:buttonFont];
    [buttonDictionary setObject:divideButton forKey:@(MMNumberKeyboardButtonDivide)];

    UIButton *equalButton = [_MMNumberKeyboardButton keyboardButtonWithStyle:MMNumberKeyboardButtonStyleGray];
    [equalButton setTitle:@"=" forState:UIControlStateNormal];
    [equalButton.titleLabel setFont:buttonFont];
    [buttonDictionary setObject:equalButton forKey:@(MMNumberKeyboardButtonEqual)];

    UIButton *acButton = [_MMNumberKeyboardButton keyboardButtonWithStyle:MMNumberKeyboardButtonStyleGray];
    [acButton setTitle:@"AC" forState:UIControlStateNormal];
    [acButton.titleLabel setFont:buttonFont];
    [buttonDictionary setObject:acButton forKey:@(MMNumberKeyboardButtonClear)];

    for (UIButton *button in buttonDictionary.objectEnumerator) {
        [button setExclusiveTouch:YES];
        [button addTarget:self action:@selector(_buttonInput:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:self action:@selector(_buttonPlayClick:) forControlEvents:UIControlEventTouchDown];

        [self addSubview:button];
    }

    UIPanGestureRecognizer *highlightGestureRecognizer =
        [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handleHighlightGestureRecognizer:)];
    [self addGestureRecognizer:highlightGestureRecognizer];

    self.buttonDictionary = buttonDictionary;

    // Initialize an array for the separators.
    self.separatorViews = [NSMutableArray array];

    // Add default action.
    [self configureSpecialKeyWithImage:dismissImage target:self action:@selector(_dismissKeyboard:)];

    // Add default return key title.
    [self setReturnKeyTitle:[self defaultReturnKeyTitle]];

    // Add default return key style.
    [self setReturnKeyButtonStyle:MMNumberKeyboardButtonStyleDone];

    // Set default layout
    self.keyboardType = MMNumberKeyboardTypeSimple;

    // Size to fit.
    [self sizeToFit];
}

#pragma mark - Input.

- (void)_handleHighlightGestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self];

    if (gestureRecognizer.state == UIGestureRecognizerStateChanged || gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        for (UIButton *button in self.buttonDictionary.objectEnumerator) {
            BOOL points = CGRectContainsPoint(button.frame, point) && !button.isHidden;

            if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
                [button setHighlighted:points];
            } else {
                [button setHighlighted:NO];
            }

            if (gestureRecognizer.state == UIGestureRecognizerStateEnded && points) {
                [button sendActionsForControlEvents:UIControlEventTouchUpInside];
            }
        }
    }
}

- (void)_buttonPlayClick:(UIButton *)button {
    [[UIDevice currentDevice] playInputClick];
}

- (void)_buttonInput:(UIButton *)button {
    __block MMNumberKeyboardButton keyboardButton = MMNumberKeyboardButtonNone;

    [self.buttonDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      MMNumberKeyboardButton k = [key unsignedIntegerValue];
      if (button == obj) {
          keyboardButton = k;
          *stop = YES;
      }
    }];

    if (keyboardButton == MMNumberKeyboardButtonNone) {
        return;
    }

    // Get first responder.
    id<UIKeyInput> keyInput = self.keyInput;
    id<MMNumberKeyboardDelegate> delegate = self.delegate;

    if (!keyInput) {
        return;
    }

    // Handle number.
    const NSInteger numberMin = MMNumberKeyboardButtonNumberMin;
    const NSInteger numberMax = MMNumberKeyboardButtonNumberMax;

    BOOL keyboardTypeCalculator = self.keyboardType == MMNumberKeyboardTypeCalculator;

    // 0-9 numbers
    if (keyboardButton >= numberMin && keyboardButton < numberMax) {
        NSNumber *number = @(keyboardButton - numberMin);
        NSString *string = number.stringValue;

        if ([delegate respondsToSelector:@selector(numberKeyboard:shouldInsertText:)]) {
            BOOL shouldInsert = [delegate numberKeyboard:self shouldInsertText:string];
            if (!shouldInsert) {
                return;
            }
        }
        if (keyboardTypeCalculator && [delegate respondsToSelector:@selector(numberKeyboard:didCalculateOperation:)]) {
            NSString *result = [self.calculatorProcessor storeOperand:string];
            [self.delegate numberKeyboard:self didCalculateOperation:result];
        } else {
            [keyInput insertText:string];
        }
    }

    // Handle backspace.
    else if (keyboardButton == MMNumberKeyboardButtonBackspace) {
        if (keyboardTypeCalculator && [delegate respondsToSelector:@selector(numberKeyboard:didCalculateOperation:)]) {
            NSString *result = [self.calculatorProcessor deleteLastDigit];
            [self.delegate numberKeyboard:self didCalculateOperation:result];
        } else {
            [keyInput deleteBackward];
        }
    }

    // Handle done.
    else if (keyboardButton == MMNumberKeyboardButtonDone) {
        BOOL shouldReturn = YES;
        if ([delegate respondsToSelector:@selector(numberKeyboardShouldReturn:)]) {
            shouldReturn = [delegate numberKeyboardShouldReturn:self];
        }

        if (shouldReturn) {
            [self _dismissKeyboard:button];
        }
    }

    // Handle special key.
    else if (keyboardButton == MMNumberKeyboardButtonSpecial) {
        dispatch_block_t handler = self.specialKeyHandler;
        if (handler) {
            handler();
        }
    }

    // Handle +
    else if (keyboardButton == MMNumberKeyboardButtonAdd || keyboardButton == MMNumberKeyboardButtonMinus || keyboardButton == MMNumberKeyboardButtonMultiply ||
             keyboardButton == MMNumberKeyboardButtonDivide) {
        if (keyboardTypeCalculator && [delegate respondsToSelector:@selector(numberKeyboard:didCalculateOperation:)]) {
            NSString *result = [self.calculatorProcessor storeOperator:keyboardButton];
            [delegate numberKeyboard:self didCalculateOperation:result];
        }
    }

    // Handle =
    else if (keyboardButton == MMNumberKeyboardButtonEqual) {
        if (keyboardTypeCalculator && [delegate respondsToSelector:@selector(numberKeyboard:didCalculateOperation:)]) {
            NSString *result = [self.calculatorProcessor computeFinalValue];
            [delegate numberKeyboard:self didCalculateOperation:result];
        }
    }

    // Handle AC
    else if (keyboardButton == MMNumberKeyboardButtonClear) {
        if (keyboardTypeCalculator && [delegate respondsToSelector:@selector(numberKeyboard:didCalculateOperation:)]) {
            NSString *result = [self.calculatorProcessor clearAll];
            [delegate numberKeyboard:self didCalculateOperation:result];
        }
    }

    // Handle .
    else if (keyboardButton == MMNumberKeyboardButtonDecimalPoint) {
        NSString *decimalText = [button titleForState:UIControlStateNormal];
        if ([delegate respondsToSelector:@selector(numberKeyboard:shouldInsertText:)]) {
            BOOL shouldInsert = [delegate numberKeyboard:self shouldInsertText:decimalText];
            if (!shouldInsert) {
                return;
            }
        }

        if (keyboardTypeCalculator && [delegate respondsToSelector:@selector(numberKeyboard:didCalculateOperation:)]) {
            NSString *result = [self.calculatorProcessor addDecimal];
            [delegate numberKeyboard:self didCalculateOperation:result];
        } else {
            [keyInput insertText:decimalText];
        }
    }
}

- (void)_backspaceRepeat:(UIButton *)button {
    id<UIKeyInput> keyInput = self.keyInput;

    if (![keyInput hasText]) {
        return;
    }

    [self _buttonPlayClick:button];
    [self _buttonInput:button];
}

- (id<UIKeyInput>)keyInput {
    id<UIKeyInput> keyInput = _keyInput;
    if (keyInput) {
        return keyInput;
    }

    keyInput = [UIResponder MM_currentFirstResponder];
    if (![keyInput conformsToProtocol:@protocol(UITextInput)]) {
        NSLog(@"Warning: First responder %@ does not conform to the UIKeyInput "
              @"protocol.",
              keyInput);
        return nil;
    }

    _keyInput = keyInput;

    return keyInput;
}

#pragma mark - Default special action.

- (void)_dismissKeyboard:(id)sender {
    UIResponder *firstResponder = self.keyInput;
    if (firstResponder) {
        [firstResponder resignFirstResponder];
    }
}

#pragma mark - Public.

- (void)configureSpecialKeyWithImage:(UIImage *)image actionHandler:(dispatch_block_t)handler {
    if (image) {
        self.specialKeyHandler = handler;
    } else {
        self.specialKeyHandler = NULL;
    }

    UIButton *button = self.buttonDictionary[@(MMNumberKeyboardButtonSpecial)];
    [button setImage:image forState:UIControlStateNormal];
}

- (void)configureSpecialKeyWithImage:(UIImage *)image target:(id)target action:(SEL)action {
    __weak typeof(self) weakTarget = target;
    __weak typeof(self) weakSelf = self;

    [self configureSpecialKeyWithImage:image
                         actionHandler:^{
                           __strong __typeof(&*weakTarget) strongTarget = weakTarget;
                           __strong __typeof(&*weakSelf) strongSelf = weakSelf;

                           if (strongTarget) {
                               NSMethodSignature *methodSignature = [strongTarget methodSignatureForSelector:action];
                               NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
                               [invocation setSelector:action];
                               if (methodSignature.numberOfArguments > 2) {
                                   [invocation setArgument:&strongSelf atIndex:2];
                               }
                               [invocation invokeWithTarget:strongTarget];
                           }
                         }];
}

- (void)setAllowsDecimalPoint:(BOOL)allowsDecimalPoint {
    if (allowsDecimalPoint != _allowsDecimalPoint) {
        _allowsDecimalPoint = allowsDecimalPoint;

        [self setNeedsLayout];
    }
}

- (MMCalculatorProcessor *)calculatorProcessor {
    if (!_calculatorProcessor) {
        _calculatorProcessor = [MMCalculatorProcessor new];
        NSLocale *locale = self.locale ?: [NSLocale currentLocale];
        NSString *decimalSeparator = [locale objectForKey:NSLocaleDecimalSeparator];
        [_calculatorProcessor setDecimalSymbol:decimalSeparator ?: @"."];
    }
    return _calculatorProcessor;
}

- (void)setReturnKeyTitle:(NSString *)title {
    if (![title isEqualToString:self.returnKeyTitle]) {
        UIButton *button = self.buttonDictionary[@(MMNumberKeyboardButtonDone)];
        if (button) {
            NSString *returnKeyTitle = (title != nil && title.length > 0) ? title : [self defaultReturnKeyTitle];
            [button setTitle:returnKeyTitle forState:UIControlStateNormal];
        }
    }
}

- (NSString *)returnKeyTitle {
    UIButton *button = self.buttonDictionary[@(MMNumberKeyboardButtonDone)];
    if (button) {
        NSString *title = [button titleForState:UIControlStateNormal];
        if (title != nil && title.length > 0) {
            return title;
        }
    }
    return [self defaultReturnKeyTitle];
}

- (NSString *)defaultReturnKeyTitle {
    return UIKitLocalizedString(@"Done");
}

- (void)setKeyboardType:(MMNumberKeyboardType)keyboardType {
    if (keyboardType != _keyboardType) {
        _keyboardType = keyboardType;
        [self sizeToFit];
        [self setNeedsLayout];
    }
}

- (void)setKeyboardAppeareance:(MMNumberKeyboardAppeareance)keyboardAppeareance {
    if (keyboardAppeareance != _keyboardAppeareance) {
        _keyboardAppeareance = keyboardAppeareance;

        [self setNeedsLayout];
    }
}

- (void)setReturnKeyButtonStyle:(MMNumberKeyboardButtonStyle)style {
    if (style != _returnKeyButtonStyle) {
        _returnKeyButtonStyle = style;

        _MMNumberKeyboardButton *button = self.buttonDictionary[@(MMNumberKeyboardButtonDone)];
        if (button) {
            button.style = style;
        }
    }
}

#pragma mark - Layout.

NS_INLINE CGRect MMButtonRectMake(CGRect rect, CGRect contentRect, UIUserInterfaceIdiom interfaceIdiom) {
    rect = CGRectOffset(rect, contentRect.origin.x, contentRect.origin.y);

    if (interfaceIdiom == UIUserInterfaceIdiomPad) {
        CGFloat inset = MMNumberKeyboardPadSpacing / 2.0f;
        rect = CGRectInset(rect, inset, inset);
    }

    return rect;
};

#if CGFLOAT_IS_DOUBLE
#define MMRound round
#else
#define MMRound roundf
#endif

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect bounds = (CGRect){.size = self.bounds.size};

    NSDictionary *buttonDictionary = self.buttonDictionary;

    // Settings.
    const UIUserInterfaceIdiom interfaceIdiom = UI_USER_INTERFACE_IDIOM();
    const CGFloat spacing = (interfaceIdiom == UIUserInterfaceIdiomPad) ? MMNumberKeyboardPadBorder : 0.0f;
    const CGFloat maximumWidth = (interfaceIdiom == UIUserInterfaceIdiomPad) ? 400.0f : CGRectGetWidth(bounds);
    const BOOL allowsDecimalPoint = self.allowsDecimalPoint;

    const CGFloat width = MIN(maximumWidth, CGRectGetWidth(bounds));
    const CGRect contentRect = (CGRect){.origin.x = MMRound((CGRectGetWidth(bounds) - width) / 2.0f),
                                        .origin.y = spacing,
                                        .size.width = width,
                                        .size.height = CGRectGetHeight(bounds) - (spacing * 2.0f)};

    // Layout.
    const CGFloat numberColumns = 4.0f;
    const CGFloat columnWidth = CGRectGetWidth(contentRect) / numberColumns;
    const CGFloat rowHeight = MMNumberKeyboardRowHeight;

    CGSize numberSize = CGSizeMake(columnWidth, rowHeight);

    // Layout numbers.
    const NSInteger numberMin = MMNumberKeyboardButtonNumberMin;
    const NSInteger numberMax = MMNumberKeyboardButtonNumberMax;
    const NSInteger numbersPerLine = 3;

    for (MMNumberKeyboardButton key = numberMin; key < numberMax; key++) {
        UIButton *button = buttonDictionary[@(key)];
        NSInteger digit = key - numberMin;

        CGRect rect = (CGRect){.size = numberSize};

        if (digit == 0) {
            if (self.keyboardType == MMNumberKeyboardTypeSimple) {
                rect.origin.y = numberSize.height * 3;
            } else {
                rect.origin.y = numberSize.height * 4;
            }
            rect.origin.x = numberSize.width;

            if (!allowsDecimalPoint) {
                rect.size.width = numberSize.width * 2.0f;
                [button setContentEdgeInsets:UIEdgeInsetsMake(0, 0, 0, numberSize.width)];
            }

        } else {
            NSUInteger idx = (digit - 1);

            NSInteger startLine = self.keyboardType == MMNumberKeyboardTypeSimple ? 0 : 1;
            NSInteger line = (idx / numbersPerLine) + startLine;
            NSInteger pos = idx % numbersPerLine;

            rect.origin.y = line * numberSize.height;
            rect.origin.x = pos * numberSize.width;
        }

        [button setFrame:MMButtonRectMake(rect, contentRect, interfaceIdiom)];
    }

    // Calculator mode layout
    if (self.keyboardType == MMNumberKeyboardTypeCalculator) {

        // Layout calculator utilities
        UIButton *acKey = buttonDictionary[@(MMNumberKeyboardButtonClear)];
        if (acKey) {
            CGRect rect = (CGRect){.size = numberSize};
            [acKey setFrame:MMButtonRectMake(rect, contentRect, interfaceIdiom)];
        }

        UIButton *divideKey = buttonDictionary[@(MMNumberKeyboardButtonDivide)];
        if (divideKey) {
            CGRect rect = (CGRect){.size = numberSize};
            rect.origin.x = numberSize.width;
            [divideKey setFrame:MMButtonRectMake(rect, contentRect, interfaceIdiom)];
        }

        UIButton *multiplyKey = buttonDictionary[@(MMNumberKeyboardButtonMultiply)];
        if (multiplyKey) {
            CGRect rect = (CGRect){.size = numberSize};
            rect.origin.x = numberSize.width * 2;
            [multiplyKey setFrame:MMButtonRectMake(rect, contentRect, interfaceIdiom)];
        }

        UIButton *minusKey = buttonDictionary[@(MMNumberKeyboardButtonMinus)];
        if (minusKey) {
            CGRect rect = (CGRect){.size = numberSize};
            rect.origin.x = numberSize.width * 3;
            rect.origin.y = numberSize.height;
            [minusKey setFrame:MMButtonRectMake(rect, contentRect, interfaceIdiom)];
        }

        UIButton *addKey = buttonDictionary[@(MMNumberKeyboardButtonAdd)];
        if (addKey) {
            CGRect rect = (CGRect){.size = numberSize};
            rect.origin.x = numberSize.width * 3;
            rect.origin.y = numberSize.height * 2;
            [addKey setFrame:MMButtonRectMake(rect, contentRect, interfaceIdiom)];
        }

        UIButton *equalKey = buttonDictionary[@(MMNumberKeyboardButtonEqual)];
        if (equalKey) {
            CGRect rect = (CGRect){.size = numberSize};
            rect.origin.x = numberSize.width * 3;
            [equalKey setFrame:MMButtonRectMake(rect, contentRect, interfaceIdiom)];
        }
    }

    // Layout backspace key.
    UIButton *backspaceKey = buttonDictionary[@(MMNumberKeyboardButtonBackspace)];
    if (backspaceKey) {
        CGRect rect = (CGRect){.size = numberSize};

        if (self.keyboardType == MMNumberKeyboardTypeSimple) {
            rect.origin.x = numberSize.width * 2; // 3rd column
            rect.origin.y = rowHeight * 3;        // 4rd row
        } else {
            rect.origin.x = numberSize.width * 2;
            rect.origin.y = numberSize.height * 4;
        }

        [backspaceKey setFrame:MMButtonRectMake(rect, contentRect, interfaceIdiom)];
    }

    // Layout done key
    UIButton *doneKey = buttonDictionary[@(MMNumberKeyboardButtonDone)];
    if (doneKey) {
        const CGSize doneKeySize = self.keyboardType == MMNumberKeyboardTypeSimple ? CGSizeMake(numberSize.width, rowHeight * 4) // Full height
                                                                                   : CGSizeMake(numberSize.width,                // Double numberSize height
                                                                                                rowHeight * 2);
        CGRect rect = (CGRect){.size = doneKeySize};

        if (self.keyboardType == MMNumberKeyboardTypeSimple) {
            rect.origin.x = numberSize.width * 3; // 4th column
        } else {
            rect.origin.x = numberSize.width * 3; // 4rd colum
            rect.origin.y = rowHeight * 3;        // 4rd row
        }

        [doneKey setFrame:MMButtonRectMake(rect, contentRect, interfaceIdiom)];
    }

    // Layout decimal point.
    UIButton *decimalPointKey = buttonDictionary[@(MMNumberKeyboardButtonDecimalPoint)];
    if (decimalPointKey) {
        CGRect rect = (CGRect){.size = numberSize};
        if (self.keyboardType == MMNumberKeyboardTypeSimple) {
            rect.origin.y = rowHeight * 3; // 4rd row
        } else {
            rect.origin.y = rowHeight * 4; // 5th row
        }

        [decimalPointKey setFrame:MMButtonRectMake(rect, contentRect, interfaceIdiom)];

        decimalPointKey.hidden = !allowsDecimalPoint;
    }

    // Layout separators if phone.
    if (interfaceIdiom != UIUserInterfaceIdiomPad) {
        NSMutableArray *separatorViews = self.separatorViews;

        const NSUInteger totalColumns = self.keyboardType == MMNumberKeyboardTypeSimple ? 3 : 4;
        const NSUInteger totalRows = numbersPerLine + 1;
        const NSUInteger numberOfSeparators = totalColumns + totalRows - 1;

        if (separatorViews.count != numberOfSeparators) {
            const NSUInteger delta = (numberOfSeparators - separatorViews.count);
            const BOOL removes = (separatorViews.count > numberOfSeparators);
            if (removes) {
                NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, delta)];
                [[separatorViews objectsAtIndexes:indexes] makeObjectsPerformSelector:@selector(removeFromSuperview)];
                [separatorViews removeObjectsAtIndexes:indexes];
            } else {
                NSUInteger separatorsToInsert = delta;
                while (separatorsToInsert--) {
                    UIView *separator = [[UIView alloc] initWithFrame:CGRectZero];
                    separator.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.1f];

                    [self addSubview:separator];
                    [separatorViews addObject:separator];
                }
            }
        }

        const CGFloat separatorDimension = 1.0f / (self.window.screen.scale ?: 1.0f);

        [separatorViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          UIView *separator = obj;

          CGRect rect = CGRectZero;

          if (idx < totalRows) {
              rect.origin.y = self.keyboardType == MMNumberKeyboardTypeSimple ? idx * rowHeight : (idx + 1) * rowHeight;
              rect.size.width = columnWidth * 3;
              rect.size.height = separatorDimension;
          } else if (idx < numberOfSeparators) {
              NSInteger col = (idx - totalRows);
              rect.origin.x = (col + 1) * columnWidth;
              rect.size.width = separatorDimension;
              rect.size.height = CGRectGetHeight(contentRect) - rowHeight;
          }

          [separator setFrame:MMButtonRectMake(rect, contentRect, interfaceIdiom)];
        }];
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    const UIUserInterfaceIdiom interfaceIdiom = UI_USER_INTERFACE_IDIOM();
    const CGFloat spacing = (interfaceIdiom == UIUserInterfaceIdiomPad) ? MMNumberKeyboardPadBorder : 0.0f;
    const NSInteger numberKeyboardRows = self.keyboardType == MMNumberKeyboardTypeSimple ? 4 : 5;
    size.height = MMNumberKeyboardRowHeight * numberKeyboardRows + (spacing * 2.0f);

    if (size.width == 0.0f) {
        size.width = [UIScreen mainScreen].bounds.size.width;
    }

    return size;
}

#pragma mark - Audio feedback.

- (BOOL)enableInputClicksWhenVisible {
    return YES;
}

#pragma mark - Accessing keyboard images.

+ (UIImage *)_keyboardImageNamed:(NSString *)name {
    NSString *resource = [name stringByDeletingPathExtension];
    NSString *extension = [name pathExtension];

    if (resource) {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        if (bundle) {
            NSString *resourcePath = [bundle pathForResource:resource ofType:extension];

            return [UIImage imageWithContentsOfFile:resourcePath];
        } else {
            return [UIImage imageNamed:name];
        }
    }
    return nil;
}

@end

@interface _MMNumberKeyboardButton ()

@property(strong, nonatomic) NSTimer *continuousPressTimer;
@property(assign, nonatomic) NSTimeInterval continuousPressTimeInterval;

@property(strong, nonatomic) UIColor *fillColor;
@property(strong, nonatomic) UIColor *highlightedFillColor;

@property(strong, nonatomic) UIColor *controlColor;
@property(strong, nonatomic) UIColor *highlightedControlColor;

@end

@implementation _MMNumberKeyboardButton

+ (_MMNumberKeyboardButton *)keyboardButtonWithStyle:(MMNumberKeyboardButtonStyle)style {
    _MMNumberKeyboardButton *button = [self buttonWithType:UIButtonTypeCustom];
    button.style = style;

    return button;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _buttonStyleDidChange];
    }
    return self;
}

- (void)setStyle:(MMNumberKeyboardButtonStyle)style {
    if (style != _style) {
        _style = style;

        [self _buttonStyleDidChange];
    }
}

- (void)_buttonStyleDidChange {
    const UIUserInterfaceIdiom interfaceIdiom = UI_USER_INTERFACE_IDIOM();
    const MMNumberKeyboardButtonStyle style = self.style;

    UIColor *fillColor = nil;
    UIColor *highlightedFillColor = nil;
    if (style == MMNumberKeyboardButtonStyleWhite) {
        fillColor = [UIColor whiteColor];
        highlightedFillColor = [UIColor colorWithRed:0.82f green:0.837f blue:0.863f alpha:1];
    } else if (style == MMNumberKeyboardButtonStyleGray) {
        if (interfaceIdiom == UIUserInterfaceIdiomPad) {
            fillColor = [UIColor colorWithRed:0.674f green:0.7f blue:0.744f alpha:1];
        } else {
            fillColor = [UIColor colorWithRed:0.81f green:0.837f blue:0.86f alpha:1];
        }
        highlightedFillColor = [UIColor whiteColor];
    } else if (style == MMNumberKeyboardButtonStyleOrange) {
        fillColor = [UIColor colorWithRed:0.96f green:0.5f blue:0 alpha:1];
        highlightedFillColor = [UIColor whiteColor];
    } else if (style == MMNumberKeyboardButtonStyleDone) {
        fillColor = [UIColor colorWithRed:0 green:0.479f blue:1 alpha:1];
        highlightedFillColor = [UIColor whiteColor];
    }

    UIColor *controlColor = nil;
    UIColor *highlightedControlColor = nil;
    if (style == MMNumberKeyboardButtonStyleDone) {
        controlColor = [UIColor whiteColor];
        highlightedControlColor = [UIColor blackColor];
    } else {
        controlColor = [UIColor blackColor];
        highlightedControlColor = [UIColor blackColor];
    }

    [self setTitleColor:controlColor forState:UIControlStateNormal];
    [self setTitleColor:highlightedControlColor forState:UIControlStateSelected];
    [self setTitleColor:highlightedControlColor forState:UIControlStateHighlighted];

    self.fillColor = fillColor;
    self.highlightedFillColor = highlightedFillColor;
    self.controlColor = controlColor;
    self.highlightedControlColor = highlightedControlColor;

    if (interfaceIdiom == UIUserInterfaceIdiomPad) {
        CALayer *buttonLayer = [self layer];
        buttonLayer.cornerRadius = 4.0f;
        buttonLayer.shadowColor = [UIColor colorWithRed:0.533f green:0.541f blue:0.556f alpha:1].CGColor;
        buttonLayer.shadowOffset = CGSizeMake(0, 1.0f);
        buttonLayer.shadowOpacity = 1.0f;
        buttonLayer.shadowRadius = 0.0f;
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];

    if (newWindow) {
        [self _updateButtonAppearance];
    }
}

- (void)_updateButtonAppearance {
    if (self.isHighlighted || self.isSelected) {
        self.backgroundColor = self.highlightedFillColor;
        self.imageView.tintColor = self.controlColor;
    } else {
        self.backgroundColor = self.fillColor;
        self.imageView.tintColor = self.highlightedControlColor;
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];

    [self _updateButtonAppearance];
}

#pragma mark - Continuous press.

- (void)addTarget:(id)target action:(SEL)action forContinuousPressWithTimeInterval:(NSTimeInterval)timeInterval {
    self.continuousPressTimeInterval = timeInterval;

    [self addTarget:target action:action forControlEvents:UIControlEventValueChanged];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    BOOL begins = [super beginTrackingWithTouch:touch withEvent:event];
    const NSTimeInterval continuousPressTimeInterval = self.continuousPressTimeInterval;

    if (begins && continuousPressTimeInterval > 0) {
        [self _beginContinuousPressDelayed];
    }

    return begins;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super endTrackingWithTouch:touch withEvent:event];
    [self _cancelContinousPressIfNeeded];
}

- (void)dealloc {
    [self _cancelContinousPressIfNeeded];
}

- (void)_beginContinuousPress {
    const NSTimeInterval continuousPressTimeInterval = self.continuousPressTimeInterval;

    if (!self.isTracking || continuousPressTimeInterval == 0) {
        return;
    }

    self.continuousPressTimer = [NSTimer scheduledTimerWithTimeInterval:continuousPressTimeInterval
                                                                 target:self
                                                               selector:@selector(_handleContinuousPressTimer:)
                                                               userInfo:nil
                                                                repeats:YES];
}

- (void)_handleContinuousPressTimer:(NSTimer *)timer {
    if (!self.isTracking) {
        [self _cancelContinousPressIfNeeded];
        return;
    }

    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)_beginContinuousPressDelayed {
    [self performSelector:@selector(_beginContinuousPress) withObject:nil afterDelay:self.continuousPressTimeInterval * 2.0f];
}

- (void)_cancelContinousPressIfNeeded {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_beginContinuousPress) object:nil];

    NSTimer *timer = self.continuousPressTimer;
    if (timer) {
        [timer invalidate];

        self.continuousPressTimer = nil;
    }
}

@end
