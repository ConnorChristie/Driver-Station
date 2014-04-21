//
//  BorderButton.m
//  Driver Station
//
//  Created by Connor on 3/29/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import "BorderButton.h"

@implementation BorderButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    self.layer.borderWidth = 1.0f;
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.cornerRadius = 8;
    self.layer.masksToBounds = YES;
}

@end
