//
//  WelcomeViewController.m
//  GifMake-ObjC
//
//  Created by Younghwan Mun on 2016-07-05.
//  Copyright © 2016 MCodeGeeks. All rights reserved.
//

#import "WelcomeViewController.h"
#import "UIImage+animatedGIF.h"

@interface WelcomeViewController ()

@end

@implementation WelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.imageView.image = [UIImage animatedImageWithGIFName: @"tinaFeyHiFive"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
