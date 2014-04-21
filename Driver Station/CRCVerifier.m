//
//  CRCVerifier.m
//  Driver Station
//
//  Created by Connor on 3/26/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import "CRCVerifier.h"

@implementation CRCVerifier

uint32_t table[256];

-(void)buildTable
{
	memset(&table, 0, 256);
    
	uint32_t poly = 0xedb88320;
    
	for (int i = 0; i < 256; i++)
	{
		uint32_t entry = (uint32_t)i;
        
		for (int j = 0; j < 8; j++)
        {
			if ((entry & 1) == 1)
            {
				entry = (entry >> 1) ^ poly;
			} else
            {
				entry = entry >> 1;
            }
        }
        
		table[i] = entry;
	}
}


-(uint32_t)verify:(void *)data length:(int)length
{
	uint32_t crc = 0xffffffff;
    
	for (int i = 0;i < length; i++)
	{
		crc = (crc >> 8) ^ table[((uint8_t *)data)[i] ^ (crc & 0xff)];
	}
    
	crc = crc ^ 0xffffffff;
    
	return crc;
}

@end