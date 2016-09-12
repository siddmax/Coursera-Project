//
//  CPCourseDetailViewController.m
//  Coursera Project
//
//  Created by Siddharth Sharma on 9/11/16.
//  Copyright © 2016 Siddharth Sharma. All rights reserved.
//

#import "CPCourseDetailViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>

static NSString *kSearchTableDidDownloadImage = @"DownloadImageNofitication";

@interface CPCourseDetailViewController ()

@end

@implementation CPCourseDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.courseTitle.text = self.course.name;
    
    UIImage *courseImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:self.course.courseID];
    if (courseImage == nil) {
        self.courseImage.image = [UIImage imageNamed:@"placeholder.png"];
    } else {
        self.courseImage.image = courseImage;
    }
    
    if (self.course.detail) {
        self.courseDescription.text = self.course.detail;
    } else {
        self.courseDescription.text = self.course.university;
        self.courseDescription.textAlignment = NSTextAlignmentCenter;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLoadImage) name:kSearchTableDidDownloadImage object:nil];
}

- (void)didLoadImage {
    UIImage *courseImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:self.course.courseID];
    
    if (courseImage != nil) {
        self.courseImage.image = courseImage;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSearchTableDidDownloadImage object:nil];
}

@end
