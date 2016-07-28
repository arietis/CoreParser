//
//  ParserException.m
//  BlindMapper
//
//  Created by Egor Taflanidi on 10/07/27 H.
//  Copyright (c) 27 Heisei RedMadRobot LLC. All rights reserved.
//

#import "ParserException.h"

@implementation ParserException

+ (instancetype)exceptionParseableNotImplementedInClass:(Class)aClass
{
    return [self exceptionAbstractMethod:@"-parsable:"
                   notImplementedInClass:aClass];
}

+ (instancetype)exceptionObjectMappingNotImplementedInClass:(Class)aClass
{
    return [self exceptionAbstractMethod:@"-mapping"
                   notImplementedInClass:aClass];
}

+ (instancetype)exceptionSanitizeNotImplementedInClass:(Class)aClass
{
    return [self exceptionAbstractMethod:@"-sanitize:"
                   notImplementedInClass:aClass];
}

+ (instancetype)exceptionObjectClassMethodNotImplementedInClass:(Class)aClass
{
    return [self exceptionAbstractMethod:@"-objectClass"
                   notImplementedInClass:aClass];
}

+ (instancetype)exceptionAbstractMethod:(NSString *)method
                  notImplementedInClass:(Class)aClass
{
    NSString *reason = [NSString stringWithFormat:@"ABSTRACT METHOD %@ NOT IMPLEMENTED IN CLASS %@",
                                                  method,
                                                  NSStringFromClass(aClass)];

    return [[self alloc] initWithName:NSStringFromClass([self class])
                               reason:reason
                             userInfo:nil];
}

@end
