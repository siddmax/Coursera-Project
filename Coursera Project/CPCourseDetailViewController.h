//
//  CPCourseDetailViewController.h
//  Coursera Project
//
//  Created by Siddharth Sharma on 9/11/16.
//  Copyright © 2016 Siddharth Sharma. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPCourse.h"

@interface CPCourseDetailViewController : UIViewController


@property (weak, nonatomic) IBOutlet UILabel *courseTitle;
@property (weak, nonatomic) IBOutlet UIImageView *courseImage;
@property (weak, nonatomic) IBOutlet UITextView *courseDescription;
@property (strong, nonatomic) CPCourse *course;

@end
