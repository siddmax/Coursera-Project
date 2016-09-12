//
//  CPCourse.h
//  Coursera Project
//
//  Created by Siddharth Sharma on 9/11/16.
//  Copyright © 2016 Siddharth Sharma. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CPCourseType) {
    CPCourseTypeCourse,
    CPCourseTypeSpecialization
};

@interface CPCourse : NSObject

@property (nonatomic, assign) CPCourseType type;
@property (nonatomic, strong) NSString *courseID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *detail;
@property (nonatomic, assign) BOOL multipleSchools;
@property (nonatomic, strong) NSString *university;
@property (nonatomic, assign) NSInteger courseCount;
@property (nonatomic, strong) NSURL *imageURL;

@end
