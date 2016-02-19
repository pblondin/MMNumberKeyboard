//
//  MMCalculatorProcessor.h
//  MMNumberKeyboard
//
//  Created by Philippe Blondin on 2016-02-17.
//  Copyright © 2016 Matías Martínez. All rights reserved.
//

#import "MMNumberKeyboard.h"
#import <UIKit/UIKit.h>

@interface MMCalculatorProcessor : NSObject

@property(strong, nonatomic) NSString *decimalSymbol; // Default is '.'

- (NSString *)storeOperand:(NSString *)operand;
- (NSString *)storeOperator:(MMNumberKeyboardButton)operator;
- (NSString *)addDecimal;
- (NSString *)computeFinalValue;
- (NSString *)clearAll;
- (NSString *)deleteLastDigit;

@end
