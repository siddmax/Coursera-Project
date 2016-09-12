//
//  ViewController.m
//  Coursera Project
//
//  Created by Siddharth Sharma on 9/11/16.
//  Copyright © 2016 Siddharth Sharma. All rights reserved.
//

#import "CPSearchViewController.h"
#import "CPCourse.h"
#import "CPSearchTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "AFHTTPSessionManager.h"
#import "CPCourseDetailViewController.h"

static NSInteger amountPerPage = 50;
static NSString *detailSegue = @"detailSegue";
static NSString *kSearchTableDidDownloadImage = @"DownloadImageNofitication";

@interface CPSearchViewController ()

@property (nonatomic, strong) NSMutableArray<CPCourse*> *courseArray;
@property (nonatomic, strong) NSString *searchText;

@end

@implementation CPSearchViewController {
    long lastIndexSeen;
    long totalCourses;
    int startIndex;
}

- (NSMutableArray *)courseArray {
    if (_courseArray == nil) {
        _courseArray = [NSMutableArray new];
    }
    
    return _courseArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    lastIndexSeen = 0;
    totalCourses = amountPerPage;
    startIndex = 0;
    
    self.searchBar.delegate = self;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    //configure table view auto sizing
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 100.f;
    
    [self addSearchButton];
    [self addTapRecognizer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    [self displayOkAlertViewWithTitle:@"Insufficient Memory"
                              message:@"You don't have enough memory to display all these photos so clearing the cache. :("];
    [[SDImageCache sharedImageCache] clearMemory];
}

- (void)addSearchButton {
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(search)];
    self.navigationItem.rightBarButtonItem = barButtonItem;
}

- (void)search {
    //reset collection view
    [self resetTableView];
    
    self.searchText = self.searchBar.text;
    
    //resign keyboard
    [self.searchBar resignFirstResponder];
    
    [self searchForCourses:self.searchText];
}

//to handle resigning keyboard if user taps on view
- (void)addTapRecognizer {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)resetTableView {
    [self.courseArray removeAllObjects];
    [self.tableView reloadData];
    self.searchText = @"";
    lastIndexSeen = 0;
    totalCourses = amountPerPage;
    startIndex = 0;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:detailSegue]) {
        //get photo from selected cell
        CPSearchTableViewCell *cell = sender;
        long index = [self.tableView indexPathForCell:cell].row;
        CPCourse *course = self.courseArray[index];
        
        //populate detail photo with image
        CPCourseDetailViewController *vc = [segue destinationViewController];
        vc.course = course;
    }
}

#pragma mark - Search Bar Delegate Methods

//search in keyboard pressed
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self search];
}

#pragma mark - Table View Delegate Methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    //keep track of last index seen for paging
    lastIndexSeen = MAX(lastIndexSeen, indexPath.row);
    if (lastIndexSeen > totalCourses-([[self.tableView visibleCells] count]*1.5)) {
        //setup for paging
        totalCourses += amountPerPage;
        [self searchForCourses:self.searchText];
    }
}

#pragma mark - Table View Data Source Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.courseArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"searchCell";
    CPSearchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    
    CPCourse *course = self.courseArray[indexPath.row];
    
    UIImage *courseImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:course.courseID];
    if (courseImage == nil) {
        cell.courseImage.image = [UIImage imageNamed:@"placeholder.png"];
    } else {
        cell.courseImage.image = courseImage;
    }
    
    cell.nameLabel.text = course.name;
    cell.uniLabel.text = course.university;
    
    if (course.type == CPCourseTypeSpecialization) {
        cell.specCourseLabel.text = [NSString stringWithFormat:@"Course: %ld",course.courseCount];
    }
    
    return cell;
}

#pragma mark - Download Methods

- (void)searchForCourses:(NSString *)text {
    //get url string
    NSString *urlString =
    [NSString stringWithFormat:
     @"https://www.coursera.org/api/catalogResults.v2?q=search&query=%@&start=%ld&limit=%ld&fields=courseId,onDemandSpecializationId,courses.v1(name,photoUrl,partnerIds),onDemandSpecializations.v1(name,logo,courseIds,partnerIds),partners.v1(name)&includes=courseId,onDemandSpecializationId,courses.v1(partnerIds)", [self encodeString:text], (long)startIndex, (long)amountPerPage];
    startIndex += amountPerPage; //increase start index for paging
    NSLog(@"url: %@", urlString);
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] init];
    [manager GET:urlString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        [self createCoursesFromArray:responseObject];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [self displayOkAlertViewWithTitle:@"Network Error"
                                  message:@"There was an error in downloading data from the server."];
    }];
}

- (void)createCoursesFromArray:(NSDictionary *)result {
    //store course id to course object to populate info from linked
    NSMutableDictionary *courseIDDict = [NSMutableDictionary new];
    
    //store partner id to uni name to populate university info
    NSMutableDictionary *partnerIDDict = [NSMutableDictionary new];
    
    //parse elements array to create course objects, store in temp dict to access in linked
    NSArray *elements = result[@"elements"];
    NSLog(@"%@", result);
    NSDictionary *entries = elements[0];
    NSArray *courseArray = entries[@"entries"];
    
    if (courseArray.count == 0) {
        [self displayOkAlertViewWithTitle:@"Invalid Search"
                                  message:@"Can't find any courses for this search. Try another search."];
        return;
    }
    
    for (NSDictionary *entryDict in courseArray) {
        CPCourse *course = [CPCourse new];
        
        if ([entryDict objectForKey:@"courseId"]) {
            course.type = CPCourseTypeCourse;
            course.courseID = entryDict[@"id"];
        } else {
            course.type = CPCourseTypeSpecialization;
            course.courseID = entryDict[@"id"];
        }
        
        [self.courseArray addObject:course];
        
        //set up course id dict
        [courseIDDict setObject:course forKey:course.courseID];
    }
    
    //setup partners dict, to populate courses with uni
    NSDictionary *linked = result[@"linked"];
    NSArray *partnersV1Array = linked[@"partners.v1"];
    for (NSDictionary *partnerDict in partnersV1Array) {
        [partnerIDDict setObject:partnerDict[@"name"] forKey:partnerDict[@"id"]];
    }
    
    NSArray *specializationV1Array = linked[@"onDemandSpecializations.v1"];
    for (NSDictionary *specDict in specializationV1Array) {
        CPCourse *course = courseIDDict[specDict[@"id"]];
        
        if (course == nil) {
            continue;
        }
        
        //course name
        course.name = specDict[@"name"];
        
        //course detail
        course.detail = specDict[@"description"];
        
        //image url
        course.imageURL = specDict[@"logo"];
        [self downloadImage:course.imageURL key:course.courseID];
        
        //spec info
        course.courseCount = [specDict[@"courseIds"] count];
        //uni name, handle multiple uni
        NSArray *partnerArray = specDict[@"partnerIds"];
        for (NSString *partnerID in partnerArray) {
            NSString *uniName = [partnerIDDict objectForKey:partnerID];
            if (course.university.length > 0) {
                course.university = [NSString stringWithFormat:@"%@, %@",course.university,uniName];
            } else {
                course.university = uniName;
            }
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
    
    //parse linked array to populate course objects, store in mutable courses array for table view data and reload
    NSArray *coursesV1Array = linked[@"courses.v1"];
    for (NSDictionary *courseDict in coursesV1Array) {
        CPCourse *course = courseIDDict[courseDict[@"id"]];
        
        if (course == nil) {
            continue;
        }
        
        //course name
        course.name = courseDict[@"name"];
        
        //course detail
        course.detail = courseDict[@"description"];
        
        //image url
        course.imageURL = courseDict[@"photoUrl"];
        [self downloadImage:course.imageURL key:course.courseID];
        
        //uni name, handle multiple uni
        NSArray *partnerArray = courseDict[@"partnerIds"];
        for (NSString *partnerID in partnerArray) {
            NSString *uniName = [partnerIDDict objectForKey:partnerID];
            if (course.university.length > 0) {
                course.university = [NSString stringWithFormat:@"%@, %@",course.university,uniName];
            } else {
                course.university = uniName;
            }
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }
}

- (void)downloadImage:(NSURL *)imageURL key:(NSString *)imageKey {
    //check if image already cached
    UIImage *image = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:imageKey];
    if (image != nil) {
        return;
    }
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:imageURL
                          options:0
                         progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                             // progression tracking code
                         }
                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                            if (image) {
                                [[SDImageCache sharedImageCache] storeImage:image forKey:imageKey toDisk:NO];
                                [[NSNotificationCenter defaultCenter] postNotificationName:kSearchTableDidDownloadImage object:nil];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self.tableView reloadData];
                                });
                            }
                        }];
}

#pragma mark - Alert View

- (void)displayOkAlertViewWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"Ok"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action){
                                                         [alertController dismissViewControllerAnimated:YES completion:nil];
                                                     }];
    [alertController addAction:actionOk];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

#pragma mark - Helper Methods

-(NSString *)encodeString:(NSString *)message
{
    NSString *msg = [message stringByReplacingOccurrencesOfString:@"%" withString:@"%25"];
    msg = [msg stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    msg = [msg stringByReplacingOccurrencesOfString:@"^" withString:@"%5E"];
    msg = [msg stringByReplacingOccurrencesOfString:@"<" withString:@"%3E"];
    msg = [msg stringByReplacingOccurrencesOfString:@">" withString:@"%3C"];
    msg = [msg stringByReplacingOccurrencesOfString:@"\"" withString:@"%22"];
    msg = [msg stringByReplacingOccurrencesOfString:@"{" withString:@"%7B"];
    msg = [msg stringByReplacingOccurrencesOfString:@"}" withString:@"%7D"];
    msg = [msg stringByReplacingOccurrencesOfString:@"[" withString:@"%5B"];
    msg = [msg stringByReplacingOccurrencesOfString:@"]" withString:@"%5D"];
    msg = [msg stringByReplacingOccurrencesOfString:@"|" withString:@"%7C"];
    msg = [msg stringByReplacingOccurrencesOfString:@"'" withString:@"%27"];
    msg = [msg stringByReplacingOccurrencesOfString:@"®" withString:@"%AE"];
    msg = [msg stringByReplacingOccurrencesOfString:@"\\n" withString:@"%0A"];
    msg = [msg lowercaseString];
    
    return msg;
}

@end
