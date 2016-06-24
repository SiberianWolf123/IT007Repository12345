//
//  ViewController.m
//  IT007FMDBQueueDemo
//
//  Created by Mac on 16/6/24.
//  Copyright © 2016年 sutdent. All rights reserved.
//

#import "ViewController.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"


@interface ViewController ()


@property (nonatomic,strong)FMDatabase *database;
@property (nonatomic,strong)NSLock *lock;
@property (nonatomic,strong)FMDatabaseQueue *queue;



@end

@implementation ViewController

- (void)createBtn {
    
    for (NSInteger i = 0; i < 9; i++) {
        
        UIButton *button=[UIButton buttonWithType:UIButtonTypeCustom];
        button.frame=CGRectMake(50 + i % 3 * (100 + 20), 50 + i / 3 * (100 + 20), 100, 100);
        button.backgroundColor=[UIColor redColor];
        button.tag = i;
        [button setTitle:[NSString stringWithFormat:@"%ld",i] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];

    }
}

- (void)testFive {
    
     NSDate *begainData = [NSDate date];
    __block NSDate *endData;
    
    for (NSInteger i =0; i < 10; i++) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                
                for (NSInteger i = 0; i < 1000; i++) {
                    
                    [self insertDBWithQueue:db];
                }
            }];
            
            endData = [NSDate date];
            
            NSTimeInterval time = [endData timeIntervalSinceDate:begainData];
            
            NSLog(@"%f",time);

        });
    }
    
    
    
    
    
}

- (void)testFour {
    
    //事物操作
    
    [self.queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        
        
//        [self insertDBWithQueue:db];
//        //回滚(如果*rollback = YES ，则对数据库的增删改查等操作都是无效的)
//        BOOL somethingHappend = YES;
//        if (somethingHappend) {
//            
//            *rollback = YES;
//        }
        
        NSDate *begainData = [NSDate date];
        
        for (NSInteger i = 0; i < 10000; i++) {
            
            [self insertDBWithQueue:db];
        }
        
        
        NSDate *endData = [NSDate date];
        
        NSTimeInterval time = [endData timeIntervalSinceDate:begainData];
        
        NSLog(@"%f",time);
        
    }];
}

- (void)testThree {
    
    
    for (NSInteger i = 0; i < 1000; i++) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [self.queue inDatabase:^(FMDatabase *db) {
                
                [self insertDBWithQueue:db];
            }];
            
            
        });
        
        
    }

     NSLog(@"插入完成");
}

- (void)testTwo {
    
    
    [self.queue inDatabase:^(FMDatabase *db) {
        
        for (NSInteger i = 0; i < 100; i++) {
            
            
            [self insertDBWithQueue:db];
        }
        
        
        
        NSLog(@"插入完成");
        
    }];
    
}

- (void)insertDBWithQueue:(FMDatabase *)db {
    
    NSString *name = [NSString stringWithFormat:@"name%d",arc4random()%100];
//    NSInteger age = arc4random()%100;
    NSString *age = [NSString stringWithFormat:@"age%d",arc4random()%100];
    [db executeUpdate:@"insert into friendsGroupTable (name,age) values (?,?)",name,age];
    
    
}

- (void)testOne {
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_group_t group = dispatch_group_create();
    
    for (NSInteger i = 0; i < 1000; i++) {
        
        dispatch_group_async(group, queue, ^{
            
            dispatch_group_enter(group);
            
            [self insertDataToBase];
            
            dispatch_group_leave(group);
            
            });

    }
//    dispatch_group_async(group, queue, ^{
//        
//        dispatch_group_enter(group);
//        
//        [self insertDataToBase];
//        
//        dispatch_group_leave(group);
//        
//    });
//    
    //组队列完成后的一个通知
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        
        
        NSLog(@"组队列完成");
        
    });
    
}

#pragma mark - - - 插入数据到数据库
- (void)insertDataToBase {
    
    [self.lock lock];
    
    [self.database open];
    
    NSString *name = [NSString stringWithFormat:@"name%d",arc4random()%100];
//    NSInteger age = arc4random()%100;
    NSString *age = [NSString stringWithFormat:@"age%d",arc4random()%100];
    [self.database executeUpdate:@"insert into friendsGroupTable (name,age) values (?,?)",name,age];
    
    
    [self.database close];
    
    [self.lock unlock];
}

- (void)buttonClick:(UIButton *)sender {
    
    switch (sender.tag) {
        case 0:
        {
            [self testOne];
            break;
        }
        case 1:
        {
            [self testTwo];
            break;
        }
        case 2:
        {
            [self testThree];
            break;
        }

        case 3:
        {
            [self testFour];
            break;
        }
        case 4:
        {
            [self testFive];
            break;
        }
        case 5:
        {
            
            break;
        }
        case 6:
        {
            
            break;
        }
        case 7:
        {
            
            break;
        }
        case 8:
        {
            
            break;
        }
       

         default:
            break;
    }
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    
    [self createBtn];
    
    self.database = [FMDatabase databaseWithPath:[self getPath:@"database.sqlite"]];
    
    [self.database open];
    
   BOOL hasCreate = [self.database executeUpdate:@"create table if not exists friendsGroupTable(id integer primary key autoincrement,name text ,age integer);"];
    
    if (hasCreate) {
        
        NSLog(@"创建成功");
    }else {
        
         NSLog(@"创建失败");
    }
    
    [self.database close];
    
    
    self.queue = [FMDatabaseQueue databaseQueueWithPath:[self getPath:@"queue.sqlite"]];
    
    [self.queue inDatabase:^(FMDatabase *db) {
       
        [db executeUpdate:@"create table if not exists friendsGroupTable(id integer primary key autoincrement,name text ,age integer);"];
       
    }];
    
    
}

#pragma mark - - - 获得路径
- (NSString *)getPath:(NSString *)str {
    
    NSString *path = NSHomeDirectory();
    NSString *docPath = [path stringByAppendingPathComponent:@"Documents"];
    
    NSString *strPath = [docPath stringByAppendingPathComponent:str];
    NSLog(@"%@",strPath);
    
    return strPath;
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
