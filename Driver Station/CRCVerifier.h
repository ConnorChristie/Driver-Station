//
//  CRCVerifier.h
//  Driver Station
//
//  Created by Connor on 3/26/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CRCVerifier : NSObject

-(void)buildTable;
-(uint32_t)verify:(void *)data length:(int)length;

@end