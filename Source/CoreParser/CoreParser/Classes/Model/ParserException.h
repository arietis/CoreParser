//
//  ParserException.h
//  BlindMapper
//
//  Created by Egor Taflanidi on 10/07/27 H.
//  Copyright (c) 27 Heisei RedMadRobot LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ParserException : NSException

+ (instancetype)exceptionParseableNotImplementedInClass:(Class)aClass;

+ (instancetype)exceptionObjectMappingNotImplementedInClass:(Class)aClass;

+ (instancetype)exceptionSanitizeNotImplementedInClass:(Class)aClass;

+ (instancetype)exceptionObjectClassMethodNotImplementedInClass:(Class)aClass;

@end
