//
//  Parser.m
//  Parser
//
//  Created by Egor Taflanidi on 10/07/27 H.
//  Copyright (c) 27 Heisei RedMadRobot LLC. All rights reserved.
//

#import "Parser.h"

#import "Fulfiller.h"
#import "ParserException.h"

@implementation Parser

#pragma mark - Конструкторы

- (instancetype)init
{
    return [self initWithFulfiller:nil];
}

- (instancetype)initWithFulfiller:(id<Fulfiller>)fulfiller
{
    if (self = [super init]) {
        self.fulfiller = fulfiller;
    }
    
    return self;
}

+ (instancetype)parser
{
    return [[[self class] alloc] init];
}

+ (instancetype)parserWithFulfiller:(id<Fulfiller>)fulfiller
{
    return [[self alloc] initWithFulfiller:fulfiller];
}

#pragma mark - Публичные методы

- (NSArray *)parseAll:(id)json
{
    NSMutableArray *entities = [[NSMutableArray alloc] init];
    
    if ([json isKindOfClass:[NSDictionary class]]) {
        [entities addObjectsFromArray:[self parseJsonDictionary:json]];
    } else if ([json isKindOfClass:[NSArray class]]) {
        [entities addObjectsFromArray:[self parseJsonArray:json]];
    }
    
    return [NSArray arrayWithArray:entities];
}

#pragma mark - Абстрактные методы

- (BOOL)parsable:(NSDictionary *)json
{
    @throw [ParserException exceptionParseableNotImplementedInClass:[self class]];
}

- (Class)objectClass
{
    @throw [ParserException exceptionObjectClassMethodNotImplementedInClass:[self class]];
}

- (NSDictionary *)mapping
{
    @throw [ParserException exceptionObjectMappingNotImplementedInClass:[self class]];
}

- (id)sanitize:(id)object
{
    @throw [ParserException exceptionSanitizeNotImplementedInClass:[self class]];
}

- (id)fulfill:(id)object from:(NSDictionary *)json
{
    if (self.fulfiller) {
        return [self.fulfiller fulfill:object from:json];
    }
    
    return object;
}

#pragma mark - Частные методы

- (NSArray *)parseJsonDictionary:(NSDictionary *)jsonDictionary
{
    NSMutableArray *entities = [[NSMutableArray alloc] init];

    if ([self parsable:jsonDictionary]) {
        [entities addObject:[self parse:jsonDictionary]];
    }

    for (id key in [jsonDictionary allKeys]) {
        [entities addObjectsFromArray:[self parseAll:jsonDictionary[key]]];
    }

    return [NSArray arrayWithArray:entities];
}

- (NSArray *)parseJsonArray:(NSArray *)jsonArray
{
    NSMutableArray *entities = [[NSMutableArray alloc] init];

    for (id json in jsonArray) {
        [entities addObjectsFromArray:[self parseAll:json]];
    }

    return [NSArray arrayWithArray:entities];
}

- (id)parse:(NSDictionary *)jsonDictionary
{
    id object = [[[self objectClass] alloc] init];

    NSDictionary *valuesDictionary = [self remapJsonDictionary:jsonDictionary];
    [object setValuesForKeysWithDictionary:valuesDictionary];

    return [self fulfill:[self sanitize:object] from:jsonDictionary];
}

- (NSDictionary *)remapJsonDictionary:(NSDictionary *)jsonDictionary
{
    NSArray *jsonKeys = [jsonDictionary allKeys];
    NSMutableDictionary *valuesDictionary = [[NSMutableDictionary alloc] init];

    NSDictionary *mapping = [self mapping];
    for (id jsonKey in jsonKeys) {
        id objectProperty = mapping[jsonKey];
        if (objectProperty) {
            valuesDictionary[objectProperty] = jsonDictionary[jsonKey];
        }
    }

    return valuesDictionary;
}

- (NSNumber *)checkNumber:(id)jsonValue
{
    if ([jsonValue isKindOfClass:[NSNumber class]]) return jsonValue;
    if ([jsonValue isKindOfClass:[NSString class]]) return @([jsonValue doubleValue]);

    return @0;
}

- (NSString *)checkString:(id)jsonValue
{
    if ([jsonValue isKindOfClass:[NSString class]]) return jsonValue;
    if ([jsonValue isKindOfClass:[NSNumber class]]) return [jsonValue stringValue];

    return @"";
}

- (NSDate *)checkDate:(id)jsonValue
{
    if ([jsonValue isKindOfClass:[NSString class]]) {
        return [self dateFromString:jsonValue];
    }
    
    if ([jsonValue isKindOfClass:[NSNumber class]]) {
        return [self dateFromNumber:jsonValue];
    }
    
    if ([jsonValue isKindOfClass:[NSDate class]]) {
        return jsonValue;
    }
    
    return [NSDate dateWithTimeIntervalSince1970:0];
}

- (BOOL)checkFieldsExist:(NSArray *)fields
                      in:(NSDictionary *)json
            absentFields:(NSArray<NSString *> * _Nullable * _Nullable)absentFields;
{
    BOOL fieldsExist = YES;
    NSMutableArray *nonExistingFields = [NSMutableArray array];

    for (NSString *field in fields) {
        BOOL fieldExist = json[field] != nil;
        if (!fieldExist) {
            fieldsExist = NO;
            [nonExistingFields addObject:field];
        }
    }

    if (absentFields) *absentFields = [NSArray arrayWithArray:nonExistingFields];
    return fieldsExist;
}

- (id)objectForKey:(NSString *)key from:(NSDictionary *)json
{
    if ([json isKindOfClass:[NSDictionary class]]) {
        if (json[key]) return json[key];
        for (NSString *jsonKey in json.allKeys) {
            id object = [self objectForKey:key from:json[jsonKey]];
            if (object) return object;
        }
    } else if ([json isKindOfClass:[NSArray class]]) {
        for (NSDictionary *subJson in json) {
            id object = [self objectForKey:key from:subJson];
            if (object) return object;
        }
    }
    
    return nil;
}

- (NSString *)stringForKey:(NSString *)key from:(NSDictionary *)json
{
    id object = [self objectForKey:key from:json];
    if (object) return [self checkString:object];
    return nil;
}

- (NSNumber *)numberForKey:(NSString *)key from:(NSDictionary *)json
{
    id object = [self objectForKey:key from:json];
    if (object) return [self checkNumber:object];
    return nil;
}

- (NSArray *)stringsForKey:(NSString *)key from:(NSDictionary *)json
{
    id array = [self objectForKey:key from:json];
    if (!array) return @[];
    
    NSMutableArray *strings = [[NSMutableArray alloc] init];
    for (id string in array) {
        [strings addObject:[self checkString:string]];
    }
    
    return [NSArray arrayWithArray:strings];
}

- (NSDate *)unixtimeDateForKey:(NSString *)key from:(NSDictionary *)json
{
    NSNumber *unixtimeDate = [self numberForKey:key from:json];
    if (unixtimeDate) return [NSDate dateWithTimeIntervalSince1970:unixtimeDate.doubleValue];
    return nil;
}

- (NSDate *)dateFromString:(NSString *)dateString
{
    if (!dateString) return [NSDate dateWithTimeIntervalSince1970:0];
    
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
    }
    
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSzzz"];
    NSDate *date = [dateFormatter dateFromString:dateString];
    
    if (!date) {
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        date = [dateFormatter dateFromString:dateString];
    }
    
    if (!date) {
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
        date = [dateFormatter dateFromString:dateString];
    }
    
    if (!date) {
        date = [NSDate dateWithTimeIntervalSince1970:0];
    }
    
    return date;
}

- (NSDate *)dateFromNumber:(NSNumber *)dateNumber
{
    if (!dateNumber) return [NSDate dateWithTimeIntervalSince1970:0];
    
    NSTimeInterval dateNumberValue = [dateNumber doubleValue];
    if (dateNumberValue > [self unixtimeYear3000]) {
        // дата в миллисекундах; необходимо разделить значение на 1000:
        dateNumberValue /= 1000.f;
    }
    
    return [NSDate dateWithTimeIntervalSince1970:dateNumberValue];
}

- (NSTimeInterval)unixtimeYear3000
{
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = 3000;
    NSCalendar *gregorianCalendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    return [[gregorianCalendar dateFromComponents:components] timeIntervalSince1970];
}

@end
