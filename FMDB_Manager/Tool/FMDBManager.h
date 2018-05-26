//
//  FMDBManager.h
//  FMDB_Manager
//
//  Created by Kerry on 16/2/20.
//  Copyright © 2016年 DKT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FMDBManager : NSObject

+ (void)insertWithModel:(id)model;
+ (void)insertWithModel:(id)model andWithSuffix:(NSString *)suffix;
+ (void)deleteObjectsWithModel:(id)model;
+ (void)deleteObjectsWithModel:(id)model andWithSuffix:(NSString *)suffix;
+ (void)deleteObjectsWithModel:(id)model WithFormat:(NSString *)format, ...;
+ (void)deleteObjectsWithModel:(id)model andWithSuffix:(NSString *)suffix WithFormat:(NSString *)format, ...;
+ (void)deleteObjectsWithModel:(id)model andWithSuffix:(NSString *)suffix andKey:(NSString *)key andValue:(NSString *)value;
+ (void)deleteTableWithModel:(id)model;
+ (void)deleteTableWithModel:(id)model andWithSuffix:(NSString *)suffix;
+ (void)updateWithModel:(id)model andWithSuffix:(NSString *)suffix andKey:(NSString *)key andValue:(NSString *)value;
+ (void)queryModel:(id)model andWithSuffix:(NSString *)suffix completed:(void(^)(NSArray *result))completed;
+ (void)queryModel:(id)model andWithSuffix:(NSString *)suffix key:(NSString *)key value:(NSString *)value completed:(void (^)(NSArray *result))completed;
+ (void)addField:(id)model andWithSuffix:(NSString *)suffix field:(NSString *)field;

@end
