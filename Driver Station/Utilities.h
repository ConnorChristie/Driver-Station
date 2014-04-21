//
//  Utilities.h
//  Driver Station
//
//  Created by Connor on 3/25/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utilities : NSObject

+(void)setShort:(void *)data value:(uint16_t)val;
+(void)setInt:(void *)data value:(uint32_t)val;
+(void)setLong:(void *)data value:(uint64_t)val;

+(uint16_t)getShort:(void *)data;
+(uint32_t)getInt:(void *)data;
+(uint64_t)getLong:(void *)data;

+(id)getFromArray:(NSArray *)controls withTag:(NSInteger)tag;

@end

@interface NSHost

+(NSHost *)currentHost;
-(id)address;

@end