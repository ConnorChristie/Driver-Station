//
//  StatusViewController.h
//  Driver Station
//
//  Created by Connor on 3/26/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StatusViewController : UITableViewController <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *rioSelect;

- (int)controlIndex;

@end
