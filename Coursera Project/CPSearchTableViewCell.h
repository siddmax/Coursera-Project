//
//  CPSearchTableViewCell.h
//  Coursera Project
//
//  Created by Siddharth Sharma on 9/11/16.
//  Copyright © 2016 Siddharth Sharma. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CPSearchTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *courseImage;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *uniLabel;
@property (weak, nonatomic) IBOutlet UILabel *specCourseLabel;

@end
