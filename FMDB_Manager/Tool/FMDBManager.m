//
//  FMDBManager.m
//  FMDB_Manager
//
//  Created by Kerry on 16/2/20.
//  Copyright © 2016年 DKT. All rights reserved.
//

#import "FMDBManager.h"

#import <objc/runtime.h>

//通过model获取类名
#define KCLASS_NAME(model) [NSString stringWithUTF8String:object_getClassName(model)]
//通过model获取属性数组数目
#define KMODEL_PROPERTYS_COUNT [[self getAllProperties:model] count]
//通过model获取属性数组
#define KMODEL_PROPERTYS [self getAllProperties:model]

@implementation FMDBManager

#pragma mark
#pragma mark ---

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

+ (id)copyWithZone:(struct _NSZone *)zone
{
    return _shareInstance;
}

#pragma mark
#pragma mark --- 获取model的属性名
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

//** 创建表操作 */
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
            [db executeUpdate:creatTableStr];
        }
    }];    
}

//** 插入操作 */
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
            NSString *str = [model valueForKey:[KMODEL_PROPERTYS objectAtIndex:i]];
            if (str == nil){
                str = @"none";
            }
            [modelPropertyArray addObject: str];
        }
        BOOL resultbool = [db executeUpdate:insertStr withArgumentsInArray:modelPropertyArray];
        if (resultbool) {
            NSLog(@"插入成功");
        }else{
            NSLog(@"插入失败");
        }
    }];
}

//** 删除数据操作 */
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
        [db executeUpdate:sql];
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
            [db executeUpdate:deletStr, value];
        }else{
            //delete from tableName
            //清空表
            NSString *deletStr = [NSString stringWithFormat:@"delete from %@",tableName];
            [db executeUpdate:deletStr];
        }
    }];
}

//** 删除表操作 */
+ (void)deleteTableWithModel:(id)model
{
    [self deleteTableWithModel:model andWithSuffix:nil];
}

+ (void)deleteTableWithModel:(id)model andWithSuffix:(NSString *)suffix
{
    FMDBManager *dbManager = [FMDBManager sharedInstance];
    [dbManager.databaseQueue inDatabase:^(FMDatabase *db) {
        NSString *tableName = suffix?[KCLASS_NAME(model) stringByAppendingString:suffix] : KCLASS_NAME(model);
        if ([db tableExists:tableName]) {
            NSString *seletTabelStr = [NSString stringWithFormat:@"drop table %@",tableName];
            BOOL resultbool = [db executeUpdate:seletTabelStr];
            if (resultbool) {
                NSLog(@"成功删除表");
            }
        }else{
            NSLog(@"%@ 表格不存在",tableName);
        }
    }];
}

//** 更新操作 */
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
        [db executeUpdate:updateStr withArgumentsInArray:propertyArray];
    }];
}


#if 0
#pragma mark
#pragma mark --- 获取沙盒路径
- (NSString *)databaseFilePath
{
    NSArray *filePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [filePath objectAtIndex:0];
    NSString *dbFilePath = [documentPath stringByAppendingPathComponent:@"db.sqlite"];
    return dbFilePath;
}

#pragma mark
#pragma mark --- 创建数据库
- (void)creatDatabase
{
    _database = [FMDatabase databaseWithPath:[self databaseFilePath]];
}

#pragma mark
#pragma mark --- 创建表
- (void)creatTable:(id)model andWithSuffix:(NSString *)suffix
{
    //先判断数据库是否存在，如果不存在，创建数据库
    if (!_database){
        [self creatDatabase];
    }
    //判断数据库是否已经打开，如果没有打开，提示失败
    if (![_database open]){
        NSLog(@"数据库打开失败");
        return;
    }
    
    //为数据库设置缓存，提高查询效率
    [_database setShouldCacheStatements:YES];
    
    //判断数据库中是否已经存在这个表，如果不存在则创建该表
    NSString *tableName = suffix?[KCLASS_NAME(model) stringByAppendingString:suffix] : KCLASS_NAME(model);
    if (![_database tableExists:tableName]){
        //  create table weibomodel (id integer primary key,userID text,userClass text,screenName text,name text,province text,city text,location text...)
        //（1）获取类名作为数据库表名
        //（2）获取类的属性作为数据表字段
        
        // 1.创建表语句头部拼接
        NSString *creatTableStrHeader = [NSString stringWithFormat:@"create table %@(id INTEGER PRIMARY KEY",tableName];
        // 2.创建表语句中部拼接
        NSString *creatTableStrMiddle =[NSString string];
        for (int i = 0; i < KMODEL_PROPERTYS_COUNT; i++)
        {
            creatTableStrMiddle = [creatTableStrMiddle stringByAppendingFormat:@",%@ TEXT",[KMODEL_PROPERTYS objectAtIndex:i]];
        }
        // 3.创建表语句尾部拼接
        NSString *creatTableStrTail =[NSString stringWithFormat:@")"];
        // 4.整句创建表语句拼接
        NSString *creatTableStr = [NSString string];
        creatTableStr = [creatTableStr stringByAppendingFormat:@"%@%@%@",creatTableStrHeader,creatTableStrMiddle,creatTableStrTail];
        [_database executeUpdate:creatTableStr];
        
        NSLog(@"创建完成");
    }
    //关闭数据库
    [_database close];
}

#pragma mark
#pragma mark --- 增加或更新
- (void)insertAndUpdateModelToDatabase:(id)model andWithSuffix:(NSString *)suffix
{
    [self insertAndUpdateModelToDatabase:model andWithSuffix:suffix andKey:nil andValue:nil];
}

#pragma mark
#pragma mark --- 增加或更新
- (void)insertAndUpdateModelToDatabase:(id)model andWithSuffix:(NSString *)suffix andKey:(NSString *)key andValue:(NSString *)value
{
    // 判断数据库是否存在
    if (!_database){
        [self creatDatabase];
    }else{
        [_database open];
    }
    
    // 判断数据库能否打开
    if (![_database open]){
        NSLog(@"数据库打开失败");
        return;
    }
    
    // 设置数据库缓存
    [_database setShouldCacheStatements:YES];
    
    // 判断是否存在对应的userModel表
    NSString *tableName = suffix?[KCLASS_NAME(model) stringByAppendingString:suffix] : KCLASS_NAME(model);
    if(![_database tableExists:tableName]){
        [self creatTable:model andWithSuffix:suffix];
    }
    
    //以上操作与创建表是做的判断逻辑相同
    //现在表中查询有没有相同的元素，如果有，做修改操作
    // select *from tableName where userID = ?
    
    // 拼接查询语句头部
    NSString *selectStrHeader = [NSString stringWithFormat:@"select * from %@ where ",tableName];
    // 拼接查询语句尾部
#warning --- 优化：考虑遍历所有属性，因为共用model不一定所有属性都有值
    NSString *selectStrTail = [NSString stringWithFormat:@"%@ = ?",[KMODEL_PROPERTYS objectAtIndex:0]];
    // 整个查询语句拼接
    NSString *selectStr = [NSString string];
    selectStr = [selectStr stringByAppendingFormat:@"%@%@",selectStrHeader,selectStrTail];
    FMResultSet * resultSet = [_database executeQuery:selectStr,[model valueForKey:[KMODEL_PROPERTYS objectAtIndex:0]]];
    
    if([resultSet next]){
        // update tableName set userID = ?,userClass = ?,screenName = ?,name = ?,province = ?,city = ?,location = ? where userID = ?
        
        // 拼接更新语句的头部
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
        [_database executeUpdate:updateStr withArgumentsInArray:propertyArray];
    }
    //向数据库中插入一条数据
    else{
        // 拼接插入语句的头部
        // insert into tableName ( userID,userClass,screenName,name,province,city,location) values (?,?,?,?,?,?,?)
        
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
            NSString *str = [model valueForKey:[KMODEL_PROPERTYS objectAtIndex:i]];
            if (str == nil){
                str = @"none";
            }
            [modelPropertyArray addObject: str];
        }
        
        [_database executeUpdate:insertStr withArgumentsInArray:modelPropertyArray];
    }
    //    关闭数据库
    [_database close];
}

#pragma mark
#pragma mark --- 根据键值对删除数据
- (void)deleteModelInDatabase:(id)model andWithSuffix:(NSString *)suffix andKey:(NSString *)key andValue:(NSString *)value
{
    // 判断是否创建数据库
    if (!_database){
        [self creatDatabase];
    }
    // 判断数据是否已经打开
    if (![_database open]){
        NSLog(@"数据库打开失败");
        return;
    }
    // 设置数据库缓存，优点：高效
    [_database setShouldCacheStatements:YES];
    
    // 判断是否有该表
    NSString *tableName = suffix?[KCLASS_NAME(model) stringByAppendingString:suffix] : KCLASS_NAME(model);
    if(![_database tableExists:tableName]){
        return;
    }
    // 删除操作
    // 拼接删除语句
    // delete from tableName where userId = ?
    
    NSString *deletStr = [NSString stringWithFormat:@"delete from %@ where %@ = ?",tableName,key];
    [_database executeUpdate:deletStr, value];
    
    // 关闭数据库
    [_database close];
}

#pragma mark
#pragma mark --- 删除表
- (void)deleteTable:(id)model andWithSuffix:(NSString *)suffix
{
    if (!_database){
        [self creatDatabase];
    }
    
    if (![_database open]) {
        NSLog(@"数据库打开失败");
        return ;
    }
    NSString *tableName = suffix?[KCLASS_NAME(model) stringByAppendingString:suffix] : KCLASS_NAME(model);
    NSString *seletTabelStr = [NSString stringWithFormat:@"drop table %@",tableName];
    [_database executeUpdate:seletTabelStr];
    //关闭数据库
    [_database close];
    
}

#pragma mark
#pragma mark --- 查询表中所有数据
- (NSArray *)selectModelArrayInDatabase:(id)model andWithSuffix:(NSString *)suffix
{
    //    select * from tableName
    if (!_database){
        [self creatDatabase];
    }
    
    if (![_database open]) {
        NSLog(@"数据库打开失败");
        return nil;
    }
    // 设置数据库缓存，优点：高效
    [_database setShouldCacheStatements:YES];
    //判断是否存在该表，不存在就创建
    NSString *tableName = suffix?[KCLASS_NAME(model) stringByAppendingString:suffix] : KCLASS_NAME(model);
    if(![_database tableExists:tableName]){
        [self creatTable:model andWithSuffix:suffix];
    }
    //定义一个可变数组，用来存放查询的结果，返回给调用者
    NSMutableArray *userModelArray = [NSMutableArray array];
    //定义一个结果集，存放查询的数据
    //拼接查询语句
    NSString *selectStr = [NSString stringWithFormat:@"select * from %@",tableName];
    FMResultSet *resultSet = [_database executeQuery:selectStr];
    //判断结果集中是否有数据，如果有则取出数据
    while ([resultSet next]){
        // 用id类型变量的类去创建对象
        id modelResult = [[[model class] alloc] init];
        for (int i = 0; i < KMODEL_PROPERTYS_COUNT; i++){
            [modelResult setValue:[resultSet stringForColumn:[KMODEL_PROPERTYS objectAtIndex:i]] forKey:[KMODEL_PROPERTYS objectAtIndex:i]];
        }
        //将查询到的数据放入数组中。
        [userModelArray addObject:modelResult];
    }
    // 关闭数据库
    [_database close];
    return userModelArray;
}
#endif

@end
