//
//  ViewController.m
//  视频倒放
//
//  Created by cc on 2020/1/19.
//  Copyright © 2020 mac. All rights reserved.
//

#import "ViewController.h"
#import "ccTableView.h"
#import "localViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    NSArray* titles = @[
        @"模版比例 1:1 竖屏",
        @"模版比例 1:1 横屏",
        @"模版比例 16:9 竖屏",
        @"模版比例 16:9 横屏",
        @"模版比例 9:16 竖屏",
        @"模版比例 9:16 横屏",

    ];
    
    ccTableView* tableView = [[ccTableView alloc] initGroupTableView:[UITableViewCell class] reuseIdentifier:NSStringFromClass([UITableViewCell class]) frame:self.view.bounds];
    
    tableView.cc_didSelectRowAtIndexPath(^(NSIndexPath * _Nonnull indexPath, UITableView * _Nonnull tableView) {
        
        localViewController* vc = [[localViewController alloc] init];
        vc.type = indexPath.row;
        [self.navigationController pushViewController:vc animated:YES];
        
    }).cc_numberOfRows(^NSInteger(NSInteger section, UITableView * _Nonnull tableView) {
        return titles.count;
    }).cc_ViewForCell(^(NSIndexPath * _Nonnull indexPath, UITableView * _Nonnull tableView, UITableViewCell * _Nonnull cell) {
        
        cell.textLabel.text = titles[indexPath.row];
        
    });
    
    [self.view addSubview:tableView];
}


@end
