//
//  FMDBManager.m
//  FMDB_Manager
//
//  Created by Kerry on 16/2/20.
//  Copyright © 2016年 DKT. All rights reserved.
//

#import "FMDBManager.h"
#import <FMDB/FMDB.h>
#import <objc/runtime.h>
//通过model获取类名
#define KCLASS_NAME(model) [NSString stringWithUTF8String:object_getClassName(model)]
//通过model获取属性数组数目
#define KMODEL_PROPERTYS_COUNT [[self getAllProperties:model] count]
//通过model获取属性数组
#define KMODEL_PROPERTYS [self getAllProperties:model]

@interface FMDBManager ()

@property (nonatomic, strong) FMDatabase *database;
@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;

@end

@implementation FMDBManager

static FMDBManager *_shareInstance = nil;
+(instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [[super allocWithZone:NULL]init];;
    });
    return _shareInstance;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone
{
    return [self sharedInstance];
}


/** 获取model的属性名 */
+ (NSArray *)getAllProperties:(id)model
{
    u_int count;
    
    objc_property_t *properties  = class_copyPropertyList([model class], &count);
    
    NSMutableArray *propertiesArray = [NSMutableArray array];
    
    for (int i = 0; i < count ; i++)
    {
        const char* propertyName = property_getName(properties[i]);
        [propertiesArray addObject: [NSString stringWithUTF8String: propertyName]];
    }
    
    free(properties);
    return propertiesArray;
}

+ (NSString *)dbPathWithDirectoryName:(NSString *)directoryName
{
    NSString *docsdir = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSFileManager *filemanage = [NSFileManager defaultManager];
    if (directoryName == nil || directoryName.length == 0) {
        docsdir = [docsdir stringByAppendingPathComponent:@"DKT"];
    } else {
        docsdir = [docsdir stringByAppendingPathComponent:directoryName];
    }
    BOOL isDir;
    BOOL exit =[filemanage fileExistsAtPath:docsdir isDirectory:&isDir];
    if (!exit || !isDir) {
        [filemanage createDirectoryAtPath:docsdir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *dbpath = [docsdir stringByAppendingPathComponent:@"db.sqlite"];
    NSLog(@"数据库地址%@",dbpath);
    return dbpath;
}

+ (NSString *)dbpath
{
    return [self dbPathWithDirectoryName:nil];
}

- (FMDatabaseQueue *)databaseQueue
{
    if (_databaseQueue == nil) {
        _databaseQueue = [[FMDatabaseQueue alloc] initWithPath:[self.class dbpath]];
    }
    return _databaseQueue;
}

/** 创建表操作 */
+ (void)createTableWithModel:(id)model
{
    [self createTableWithModel:model andWithSuffix:nil];
}

+ (void)createTableWithModel:(id)model andWithSuffix:(NSString *)suffix
{
    FMDBManager *dbManager = [self sharedInstance];
    [dbManager.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *tableName = suffix?[KCLASS_NAME(model) stringByAppendingString:suffix] : KCLASS_NAME(model);
        if (![db tableExists:tableName]) {
            //判断数据库中是否已经存在这个表，如果不存在则创建该表
            //  create table tableName (id integer primary key,userID text,userClass text,screenName text,name text,province text,city text,location text...)
            //（1）获取类名作为数据库表名
            //（2）获取类的属性作为数据表字段
            
            // 1.创建表语句头部拼接
            NSString *creatTableStrHeader = [NSString stringWithFormat:@"create table %@(id INTEGER PRIMARY KEY",tableName];
            // 2.创建表语句中部拼接
            NSString *creatTableStrMiddle =[NSString string];
            for (int i = 0; i < KMODEL_PROPERTYS_COUNT; i++){
                creatTableStrMiddle = [creatTableStrMiddle stringByAppendingFormat:@",%@ TEXT",[KMODEL_PROPERTYS objectAtIndex:i]];
            }
            // 3.创建表语句尾部拼接
            NSString *creatTableStrTail =[NSString stringWithFormat:@")"];
            // 4.整句创建表语句拼接
            NSString *creatTableStr = [NSString string];
            creatTableStr = [creatTableStr stringByAppendingFormat:@"%@%@%@",creatTableStrHeader,creatTableStrMiddle,creatTableStrTail];
            if ([db executeUpdate:creatTableStr])
            {
                NSLog(@"创建表成功");
            }
            else
            {
                NSLog(@"创建表失败");
            }
        }
    }];
}

/** 插入操作 */
+ (void)insertWithModel:(id)model
{
    [self insertWithModel:model andWithSuffix:nil];
}

+ (void)insertWithModel:(id)model andWithSuffix:(NSString *)suffix
{
    [self createTableWithModel:model andWithSuffix:suffix];
    FMDBManager *dbManager = [self sharedInstance];
    // 判断是否存在对应的userModel表
    [dbManager.databaseQueue inDatabase:^(FMDatabase *db) {
        // 拼接插入语句的头部
        // insert into tableName ( userID,userClass,screenName,name,province,city,location) values (?,?,?,?,?,?,?)
        
        NSString *tableName = suffix?[KCLASS_NAME(model) stringByAppendingString:suffix] : KCLASS_NAME(model);
        NSString *insertStrHeader = [NSString stringWithFormat:@"INSERT INTO %@ (",tableName];
        // 拼接插入语句的中部1
        NSString *insertStrMiddleOne = [NSString string];
        for (int i = 0; i < KMODEL_PROPERTYS_COUNT; i++){
            insertStrMiddleOne = [insertStrMiddleOne stringByAppendingFormat:@"%@",[KMODEL_PROPERTYS objectAtIndex:i]];
            
            if (i != KMODEL_PROPERTYS_COUNT -1){
                insertStrMiddleOne = [insertStrMiddleOne stringByAppendingFormat:@","];
            }
        }
        // 拼接插入语句的中部2
        NSString *insertStrMiddleTwo = [NSString stringWithFormat:@") VALUES ("];
        // 拼接插入语句的中部3
        NSString *insertStrMiddleThree = [NSString string];
        for (int i = 0; i < KMODEL_PROPERTYS_COUNT; i++){
            
            insertStrMiddleThree = [insertStrMiddleThree stringByAppendingFormat:@"?"];
            if (i != KMODEL_PROPERTYS_COUNT-1){
                insertStrMiddleThree = [insertStrMiddleThree stringByAppendingFormat:@","];
            }
        }
        // 拼接插入语句的尾部
        NSString *insertStrTail = [NSString stringWithFormat:@")"];
        // 整句插入语句拼接
        NSString *insertStr = [NSString string];
        insertStr = [insertStr stringByAppendingFormat:@"%@%@%@%@%@",insertStrHeader,insertStrMiddleOne,insertStrMiddleTwo,insertStrMiddleThree,insertStrTail];
        NSMutableArray *modelPropertyArray = [NSMutableArray array];
        for (int i = 0; i < KMODEL_PROPERTYS_COUNT; i++){
            id object = [model valueForKey:[KMODEL_PROPERTYS objectAtIndex:i]];
            if (object == nil){
                object = @"none";
            }
            [modelPropertyArray addObject: object];
        }
        BOOL resultbool = [db executeUpdate:insertStr withArgumentsInArray:modelPropertyArray];
        if (resultbool) {
            NSLog(@"插入成功");
        }else{
            NSLog(@"插入失败");
        }
    }];
}

/** 删除数据操作 */
+ (void)deleteObjectsWithModel:(id)model
{
    [self deleteObjectsWithModel:model andWithSuffix:nil];
}

+ (void)deleteObjectsWithModel:(id)model andWithSuffix:(NSString *)suffix
{
    [self deleteObjectsWithModel:model andWithSuffix:suffix andKey:nil andValue:nil];
}

+ (void)deleteObjectsWithModel:(id)model WithFormat:(NSString *)format, ...
{
    [self deleteObjectsWithModel:model andWithSuffix:nil WithFormat:format];
}

+ (void)deleteObjectsWithModel:(id)model andWithSuffix:(NSString *)suffix WithFormat:(NSString *)format, ...
{
    va_list ap;
    va_start(ap, format);
    NSString *criteria = [[NSString alloc] initWithFormat:format locale:[NSLocale currentLocale] arguments:ap];
    va_end(ap);
    
    FMDBManager *dbManager = [FMDBManager sharedInstance];
    [dbManager.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = suffix?[KCLASS_NAME(model) stringByAppendingString:suffix] : KCLASS_NAME(model);
        //多条件删除
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ %@ ",tableName,criteria];
        if ([db executeUpdate:sql])
        {
            NSLog(@"删除成功");
        }
        else
        {
            NSLog(@"删除失败");
        }
    }];
}

+ (void)deleteObjectsWithModel:(id)model andWithSuffix:(NSString *)suffix andKey:(NSString *)key andValue:(NSString *)value
{
    FMDBManager *dbManager = [FMDBManager sharedInstance];
    [dbManager.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = suffix?[KCLASS_NAME(model) stringByAppendingString:suffix] : KCLASS_NAME(model);
        if (key && value) {
            //delete from tableName where userId = ?
            //单个条件删除
            NSString *deletStr = [NSString stringWithFormat:@"delete from %@ where %@ = ?",tableName,key];
            if ([db executeUpdate:deletStr, value])
            {
                NSLog(@"删除成功");
            }
            else
            {
                NSLog(@"删除失败");
            }
        }
        else
        {
            //delete from tableName
            //清空表
            NSString *deletStr = [NSString stringWithFormat:@"delete from %@",tableName];
            if ([db executeUpdate:deletStr])
            {
                NSLog(@"成功清空表");
            }
            else
            {
                NSLog(@"清空表失败");
            }
        }
    }];
}

/** 删除表操作 */
+ (void)deleteTableWithModel:(id)model
{
    [self deleteTableWithModel:model andWithSuffix:nil];
}

+ (void)deleteTableWithModel:(id)model andWithSuffix:(NSString *)suffix
{
    FMDBManager *dbManager = [FMDBManager sharedInstance];
    [dbManager.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = suffix?[KCLASS_NAME(model) stringByAppendingString:suffix] : KCLASS_NAME(model);
        if ([db tableExists:tableName])
        {
            NSString *seletTabelStr = [NSString stringWithFormat:@"drop table %@",tableName];
            if ([db executeUpdate:seletTabelStr])
            {
                NSLog(@"成功删除表");
            }
            else
            {
                NSLog(@"删除表失败");
            }
        }
        else
        {
            NSLog(@"%@ 表格不存在",tableName);
        }
    }];
}

/** 更新操作 */
+ (void)updateWithModel:(id)model andWithSuffix:(NSString *)suffix andKey:(NSString *)key andValue:(NSString *)value
{
    FMDBManager *dbManager = [FMDBManager sharedInstance];
    [dbManager.databaseQueue inDatabase:^(FMDatabase *db) {
        // update tableName set userID = ?,userClass = ?,screenName = ?,name = ?,province = ?,city = ?,location = ? where userID = ?
        // 拼接更新语句的头部
        NSString *tableName = suffix?[KCLASS_NAME(model) stringByAppendingString:suffix] : KCLASS_NAME(model);
        NSString *updateStrHeader = [NSString stringWithFormat:@"update %@ set ",tableName];
        // 拼接更新语句的中部
        NSString *updateStrMiddle = [NSString string];
        for (int i = 0; i< KMODEL_PROPERTYS_COUNT; i++)
        {
            updateStrMiddle = [updateStrMiddle stringByAppendingFormat:@"%@ = ?",[KMODEL_PROPERTYS objectAtIndex:i]];
            if (i != KMODEL_PROPERTYS_COUNT -1) {
                updateStrMiddle = [updateStrMiddle stringByAppendingFormat:@","];
            }
        }
        // 拼接更新语句的尾部
        NSString *updateStrTail = [NSString stringWithFormat:@" where %@ = %@",key,value];
        // 整句拼接更新语句
        NSString *updateStr = [NSString string];
        updateStr = [updateStr stringByAppendingFormat:@"%@%@%@",updateStrHeader,updateStrMiddle,updateStrTail];
        
        NSMutableArray *propertyArray = [NSMutableArray array];
        
        for (int i = 0; i < KMODEL_PROPERTYS_COUNT; i++)
        {
            NSString *midStr = [model valueForKey:[KMODEL_PROPERTYS objectAtIndex:i]];
            // 判断属性值是否为空
            if (midStr == nil)
            {
                midStr = @"none";
            }
            [propertyArray addObject:midStr];
        }
        if ([db executeUpdate:updateStr withArgumentsInArray:propertyArray]) {
            NSLog(@"更新成功");
        } else {
            NSLog(@"更新失败");
        }
    }];
}

/** 查询表中所有数据 */
+ (void)queryModel:(id)model andWithSuffix:(NSString *)suffix completed:(void (^)(NSArray *))completed
{
    [self queryModel:model andWithSuffix:suffix key:nil value:nil completed:^(NSArray *result) {
        if (completed) {
            completed(result);
        }
    }];
}

/** 查询表中字段等于某个值的所有记录 */
+ (void)queryModel:(id)model andWithSuffix:(NSString *)suffix key:(NSString *)key value:(NSString *)value completed:(void (^)(NSArray *))completed
{
    //定义一个可变数组，用来存放查询的结果，返回给调用者
    NSMutableArray *result = [NSMutableArray array];
    FMDBManager *dbManager = [FMDBManager sharedInstance];
    [dbManager.databaseQueue inDatabase:^(FMDatabase *db) {
        
        NSString *tableName = suffix?[KCLASS_NAME(model) stringByAppendingString:suffix] : KCLASS_NAME(model);
        if ([db tableExists:tableName])
        {
            //定义一个结果集，存放查询的数据
            //拼接查询语句
            NSString *selectStr = @"";
            if (key && value) {
                selectStr = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ = %@",tableName, key, value];
            } else {
                selectStr = [NSString stringWithFormat:@"SELECT * FROM %@",tableName];
            }
            FMResultSet *resultSet = [db executeQuery:selectStr];
            //判断结果集中是否有数据，如果有则取出数据
            while ([resultSet next])
            {
                // 用id类型变量的类去创建对象
                id modelResult = [[[model class] alloc] init];
                for (int i = 0; i < KMODEL_PROPERTYS_COUNT; i++)
                {
                    [modelResult setValue:[resultSet stringForColumn:[KMODEL_PROPERTYS objectAtIndex:i]] forKey:[KMODEL_PROPERTYS objectAtIndex:i]];
                }
                //将查询到的数据放入数组中。
                [result addObject:modelResult];
            }
            if (completed) {
                completed(result);
            }
        }
        else
        {
            if (completed) {
                completed(nil);
            }
            NSLog(@"%@ 表格不存在",tableName);
        }
    }];
}

+ (void)addField:(id)model andWithSuffix:(NSString *)suffix field:(NSString *)field
{
    FMDBManager *dbManager = [FMDBManager sharedInstance];
    [dbManager.databaseQueue inDatabase:^(FMDatabase *db) {
        
        NSString *tableName = suffix?[KCLASS_NAME(model) stringByAppendingString:suffix] : KCLASS_NAME(model);
        if ([db tableExists:tableName])
        {
            // 判断字段是否存在
            if (![db columnExists:field inTableWithName:tableName]){
                NSString *alertStr = [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ INTEGER",tableName,field];
                if([db executeUpdate:alertStr]){
                    NSLog(@"%@ 字段插入成功", field);
                }else{
                    NSLog(@"%@ 字段插入失败", field);
                }
            }
        }
        else
        {
            NSLog(@"%@ 表格不存在",tableName);
        }
    }];
    
}

@end
