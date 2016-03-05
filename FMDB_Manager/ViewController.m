//
//  ViewController.m
//  FMDB_Manager
//
//  Created by Kerry on 16/2/20.
//  Copyright © 2016年 DKT. All rights reserved.
//

#import "ViewController.h"

#import "Dog.h"
#import "FMDBManager.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, strong) NSArray *headerTitleArray;

@end

@implementation ViewController

#pragma mark life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"FMDB_Manager";
    
    self.headerTitleArray = @[@"  插入操作",@"  修改操作",@"  删除操作",@"  查询操作"];
    self.dataArray = [[NSMutableArray alloc] init];
    NSArray *insertArray = @[@"插入"];
    NSArray *updateArray = @[@"修改"];
    NSArray *deletArray = @[@"单参数条件删除数据",@"多参数条件删除数据",@"清空表",@"删除表"];
    NSArray *findArray = @[@"查询一条数据",@"条件查询",@"查询全部"];
    [self.dataArray addObject:insertArray];
    [self.dataArray addObject:updateArray];
    [self.dataArray addObject:deletArray];
    [self.dataArray addObject:findArray];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
}

#pragma mark UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cellID"];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (3 == indexPath.section) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.text = self.dataArray[indexPath.section][indexPath.row];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataArray[section] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataArray.count;
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel *headerTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.tableHeaderView.frame.size.width, tableView.tableHeaderView.frame.size.height)];
    headerTitleLabel.text = self.headerTitleArray[section];
    headerTitleLabel.textColor = [UIColor blueColor];
    headerTitleLabel.font = [UIFont systemFontOfSize:14.0];
    return headerTitleLabel;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
            /*!
             *  @brief 插入操作
             */
        case 0:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    for (int i = 0; i < 10; i ++)
                    {
                        Dog *dog = [Dog new];
                        dog.name = [NSString stringWithFormat:@"dog%d",i];
                        dog.age = i;
                        [FMDBManager insertWithModel:dog];
                    }
                    for (int i = 0; i < 10; i ++)
                    {
                        Dog *dog = [Dog new];
                        dog.name = [NSString stringWithFormat:@"dog%d",i];
                        dog.age = i;
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [FMDBManager insertWithModel:dog andWithSuffix:@"_two"];
                        });
                    }

                }
                    break;
                    
                default:
                    break;
            }
        }
            break;
            /*!
             *  @brief 修改操作
             */
        case 1:
        {
            switch (indexPath.row)
            {
                case 0:
                    
                    break;
                    
                default:
                    break;
            }
        }
            break;
            /*!
             *  @brief 删除操作
             */
        case 2:
        {
            switch (indexPath.row)
            {
                case 0:
                    
                    break;
                case 1:
                    
                    break;
                case 2:
                    
                    break;
                case 3:
                {
                    [FMDBManager deleteTableWithModel:[Dog new]];
                    [FMDBManager deleteTableWithModel:[Dog new] andWithSuffix:@"_two"];
                }
                    break;
                    
                default:
                    break;
            }
        }
            break;
            /*!
             *  @brief 查询操作
             */
        case 3:
        {
            switch (indexPath.row)
            {
                case 0:
                    
                    break;
                case 1:
                    
                    break;
                case 2:
                    
                    break;
                    
                default:
                    break;
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
