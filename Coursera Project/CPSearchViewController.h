//
//  ViewController.h
//  Coursera Project
//
//  Created by Siddharth Sharma on 9/11/16.
//  Copyright © 2016 Siddharth Sharma. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CPSearchViewController : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end

