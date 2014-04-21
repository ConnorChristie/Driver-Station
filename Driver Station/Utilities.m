//
//  Utilities.m
//  Driver Station
//
//  Created by Connor on 3/25/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import "Utilities.h"

@implementation Utilities

+(uint16_t)getShort:(void *)data
{
	union
	{
		uint8_t data[2];
		uint16_t value;
	}temp;
    
	temp.data[0] = ((uint8_t *)data)[1];
	temp.data[1] = ((uint8_t *)data)[0];
    
	return temp.value;
}

+(uint32_t)getInt:(void *)data
{
	union
	{
		uint8_t data[4];
		uint32_t value;
	}temp;
    
	temp.data[0] = ((uint8_t *)data)[3];
	temp.data[1] = ((uint8_t *)data)[2];
	temp.data[2] = ((uint8_t *)data)[1];
	temp.data[3] = ((uint8_t *)data)[0];
    
	return temp.value;
}

+(uint64_t)getLong:(void *)data
{
	union
	{
		uint8_t data[8];
		uint64_t value;
	}temp;
    
	temp.data[0] = ((uint8_t *)data)[7];
	temp.data[1] = ((uint8_t *)data)[6];
	temp.data[2] = ((uint8_t *)data)[5];
	temp.data[3] = ((uint8_t *)data)[4];
	temp.data[4] = ((uint8_t *)data)[3];
	temp.data[5] = ((uint8_t *)data)[2];
	temp.data[6] = ((uint8_t *)data)[1];
	temp.data[7] = ((uint8_t *)data)[0];
    
	return temp.value;
}

+(void)setShort:(void *)data value:(uint16_t)val
{
	union
	{
		uint8_t data[2];
		uint16_t value;
	}temp;
    
	temp.value = val;
    
	((uint8_t *)data)[1] = temp.data[0];
	((uint8_t *)data)[0] = temp.data[1];
}

+(void)setInt:(void *)data value:(uint32_t)val
{
	union
	{
		uint8_t data[4];
		uint32_t value;
	}temp;
    
	temp.value = val;
    
	((uint8_t *)data)[3] = temp.data[0];
	((uint8_t *)data)[2] = temp.data[1];
	((uint8_t *)data)[1] = temp.data[2];
	((uint8_t *)data)[0] = temp.data[3];
}

+(void)setLong:(void *)data value:(uint64_t)val
{
	union
	{
		uint8_t data[8];
		uint64_t value;
	}temp;
    
	temp.value = val;
    
	((uint8_t *)data)[7] = temp.data[0];
	((uint8_t *)data)[6] = temp.data[1];
	((uint8_t *)data)[5] = temp.data[2];
	((uint8_t *)data)[4] = temp.data[3];
	((uint8_t *)data)[3] = temp.data[4];
	((uint8_t *)data)[2] = temp.data[5];
	((uint8_t *)data)[1] = temp.data[6];
	((uint8_t *)data)[0] = temp.data[7];
}

+(id)getFromArray:(NSArray *)controls withTag:(NSInteger)tag
{
	for (int i = 0; i < [controls count]; i++)
	{
		UIControl *c = [controls objectAtIndex:i];
		
        if (c.tag == tag)
		{
			return c;
		}
	}
    
	return nil;
}

@end