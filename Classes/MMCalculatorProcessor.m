//
//  MMCalculatorProcessor.m
//  MMNumberKeyboard
//
//  Created by Philippe Blondin on 2016-02-17.
//  Copyright © 2016 Matías Martínez. All rights reserved.
//
//  Objective-c port from https://github.com/sprint84/CalculatorKeyboard/blob/master/CalculatorKeyboard/CalculatorProcessor.swift

#import "MMCalculatorProcessor.h"

@interface MMCalculatorProcessor () {
    BOOL shouldStartNewOperand;
}

@property(strong, nonatomic) NSString *previousOperand;
@property(strong, nonatomic) NSString *currentOperand;
@property(nonatomic) MMNumberKeyboardButton storedOperator;

@end

@implementation MMCalculatorProcessor

#pragma mark - Init

- (instancetype)init {
    self = [super init];
    if (self) {
        self.decimalSymbol = @".";
        self.previousOperand = [self resetOperand];
        self.currentOperand = [self resetOperand];
    }
    return self;
}

#pragma mark - Accessors

- (void)setDecimalSymbol:(NSString *)decimalSymbol {
    if (decimalSymbol && [decimalSymbol length] == 1) {
        _decimalSymbol = decimalSymbol;
        [self clearAll];
    }
}

#pragma mark - Calculator functions

- (NSString *)storeOperand:(NSString *)operand {
    shouldStartNewOperand = NO;

    if ([self.currentOperand isEqualToString:@"0"]) {
        self.currentOperand = operand;
    } else {
        self.currentOperand = [NSString stringWithFormat:@"%@%@", self.currentOperand, operand];
    }

    if (self.storedOperator == MMNumberKeyboardButtonEqual) {
        self.currentOperand = operand;
        self.storedOperator = MMNumberKeyboardButtonNone;
    }
    return self.currentOperand;
}

- (NSString *)storeOperator:(MMNumberKeyboardButton) operator{
    self.storedOperator = operator;

    if (shouldStartNewOperand) {
        return self.previousOperand;
    } else {
        shouldStartNewOperand = YES;
    }

    self.previousOperand = self.currentOperand;
    self.currentOperand = [self resetOperand];
    return self.previousOperand;
}

- (NSString *)addDecimal {
    if ([self.currentOperand rangeOfString:self.decimalSymbol].location == NSNotFound) {
        self.currentOperand = [NSString stringWithFormat:@"%@%@", [self currentOperand], [self decimalSymbol]];
    }
    return self.currentOperand;
}

- (NSString *)computeFinalValue {
    double value1 = [self.previousOperand doubleValue];
    double value2 = [self.currentOperand doubleValue];
    double output = 0.0;

    if (shouldStartNewOperand) {
        return self.currentOperand;
    }

    switch (self.storedOperator) {
    case MMNumberKeyboardButtonEqual: {
        return self.currentOperand;
    }
    case MMNumberKeyboardButtonAdd: {
        output = value1 + value2;
        break;
    }
    case MMNumberKeyboardButtonMinus: {
        output = value1 - value2;
        break;
    }
    case MMNumberKeyboardButtonMultiply: {
        output = value1 * value2;
        break;
    }
    case MMNumberKeyboardButtonDivide: {
        output = value1 / value2;
        break;
    }
    }
    self.currentOperand = [[self formatValue:output] mutableCopy];
    //    self.previousOperand = [self resetOperand];
    self.storedOperator = MMNumberKeyboardButtonEqual;
    return self.currentOperand;
}

- (NSString *)deleteLastDigit {
    if ([self.currentOperand length] > 1) {
        self.currentOperand = [self.currentOperand substringToIndex:[self.currentOperand length] - 1];
    } else {
        self.currentOperand = [self resetOperand];
    }

    return self.currentOperand;
}

- (NSString *)clearAll {
    self.storedOperator = MMNumberKeyboardButtonNone;
    self.previousOperand = [self resetOperand];
    self.currentOperand = [self resetOperand];
    return self.currentOperand;
}

#pragma mark - Private

- (NSString *)convertOperandToDecimals:(NSString *)operand {
    return [NSString stringWithFormat:@"%@.00", operand];
}

- (NSString *)resetOperand {
    return @"0";
}

- (NSString *)formatValue:(double)value {
    return [NSString stringWithFormat:@"%f", value];
}

@end
