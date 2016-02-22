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

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSArray *title = @[@"重置",@"插入",@"更新",@"多参数条件删除数据",@"单参数条件删除数据",@"清空表",@"删除表",@"查询一条数据",@"条件查询",@"查询全部"];
    float maxY = 40;
    for (int i = 0; i < title.count; i ++) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(self.view.center.x - 150, maxY+10, 300, 40)];
        [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = i;
        [button setTitle:title[i] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor purpleColor];
        [self.view addSubview:button];
        maxY = CGRectGetMaxY(button.frame);
    }
}

- (void)buttonClick:(UIButton *)button
{
    switch (button.tag)
    {
        case 0:
            
            break;
        case 1:
        {
            {
                for (int i = 0; i < 10; i ++)
                {
                    Dog *dog = [Dog new];
                    dog.name = [NSString stringWithFormat:@"dog%d",i];
                    dog.age = i;
                    //            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [FMDBManager insertWithModel:dog];
                    //            });
                }
                for (int i = 0; i < 10; i ++)
                {
                    Dog *dog = [Dog new];
                    dog.name = [NSString stringWithFormat:@"dog%d",i];
                    dog.age = i;
                    //            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [FMDBManager insertWithModel:dog andWithSuffix:@"_two"];
                    //            });
                }
            }
        }
            break;
        case 2:
            
            break;
        case 3:
            
            break;
        case 4:
            
            break;
        case 5:
            
            break;
        case 6:
        {
            [FMDBManager deleteTableWithModel:[Dog new]];
            [FMDBManager deleteTableWithModel:[Dog new] andWithSuffix:@"_two"];
        }
            
            break;
        case 7:
            
            break;
        case 8:
            
            break;
        case 9:
            
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
