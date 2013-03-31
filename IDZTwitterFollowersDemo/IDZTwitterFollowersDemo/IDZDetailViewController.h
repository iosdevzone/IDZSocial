//
//  IDZDetailViewController.h
//  IDZTwitterFollowersDemo
//
//  Created by idz on 3/31/13.
//  Copyright (c) 2013 idz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IDZDetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
