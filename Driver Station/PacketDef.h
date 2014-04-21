//
//  PacketDef.h
//  Driver Station
//
//  Created by Connor on 3/25/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PacketDef

struct FRCCommonControlData
{
	uint16_t packetIndex;
	uint8_t control;
    
	uint8_t dsDigitalIn;
	uint16_t teamID;
    
	char dsID_Alliance;
	char dsID_Position;
    
	union {
		int8_t stick0Axes[6];
		struct {
			int8_t stick0Axis1;
			int8_t stick0Axis2;
			int8_t stick0Axis3;
			int8_t stick0Axis4;
			int8_t stick0Axis5;
			int8_t stick0Axis6;
		}axis;
	}stick0;
	uint16_t stick0Buttons;		// Left-most 4 bits are unused
    
	union {
		int8_t stick1Axes[6];
		struct {
			int8_t stick1Axis1;
			int8_t stick1Axis2;
			int8_t stick1Axis3;
			int8_t stick1Axis4;
			int8_t stick1Axis5;
			int8_t stick1Axis6;
		}axis;
	}stick1;
	uint16_t stick1Buttons;		// Left-most 4 bits are unused
    
	union {
		int8_t stick2Axes[6];
		struct {
			int8_t stick2Axis1;
			int8_t stick2Axis2;
			int8_t stick2Axis3;
			int8_t stick2Axis4;
			int8_t stick2Axis5;
			int8_t stick2Axis6;
		}axis;
	}stick2;
	uint16_t stick2Buttons;		// Left-most 4 bits are unused
    
	union {
		int8_t stick3Axes[6];
		struct {
			int8_t stick3Axis1;
			int8_t stick3Axis2;
			int8_t stick3Axis3;
			int8_t stick3Axis4;
			int8_t stick3Axis5;
			int8_t stick3Axis6;
		}axis;
	}stick3;
	uint16_t stick3Buttons;		// Left-most 4 bits are unused
    
	//Analog inputs are 10 bit right-justified
	uint16_t analog1;
	uint16_t analog2;
	uint16_t analog3;
	uint16_t analog4;
    
	uint64_t cRIOChecksum;
    
	uint64_t FPGAChecksum0;
	uint64_t FPGAChecksum1;
    
	char versionData[8];
    
	uint8_t highEndData[938];
	uint32_t CRC;
};

struct RobotDataPacket
{
	uint8_t control;
    
	uint8_t batteryVolts;
	uint8_t batteryMV;
    
	union {
		uint8_t dio;
		struct {
			uint8_t out1 : 1;
			uint8_t out2 : 1;
			uint8_t out3 : 1;
			uint8_t out4 : 1;
			uint8_t out5 : 1;
			uint8_t out6 : 1;
			uint8_t out7 : 1;
			uint8_t out8 : 1;
		}outputs;
	}digitalOutput;
    
	uint8_t unknown1[4];
	uint16_t teamNumber;
    
	char macAddr[6];
    
	uint8_t unknow2[14];
	uint16_t packetCount;
    
	uint8_t highData[988];
    
    char userLine1[21];
    char userLine2[21];
    char userLine3[21];
    char userLine4[21];
    char userLine5[21];
    char userLine6[21];
    
	uint32_t crc;
};

@end