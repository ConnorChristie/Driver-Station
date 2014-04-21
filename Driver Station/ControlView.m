//
//  ControlView.m
//  Driver Station
//
//  Created by Connor on 3/28/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import "ControlView.h"

#import "AppDelegate.h"
#import "CameraViewController.h"

#define Max .9921875

@implementation ControlView
{
    AppDelegate *delegate;
    
    CGPoint leftTouch;
    CGPoint rightTouch;
    
    CGRect dPadLeft;
    CGRect dPadRight;
    
    BOOL wasInsideLeft;
    BOOL wasInsideRight;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    delegate = [[UIApplication sharedApplication] delegate];
    
    leftTouch = CGPointZero;
	rightTouch = CGPointZero;
    
    [self performSelector:@selector(adjust) withObject:nil afterDelay:.1];
}

- (void)adjust
{
    int widthDiff = 568 - delegate.width;
    int dimension = 180 - (widthDiff / 4);
    
	dPadLeft = CGRectMake(15, self.frame.size.height / 2 - dimension / 2 - 11, dimension, dimension);
    dPadRight = CGRectMake(delegate.width - dimension - 15, self.frame.size.height / 2 - dimension / 2 - 11, dimension, dimension);
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef g = UIGraphicsGetCurrentContext();
    
	CGFloat color[] = {0.0, 0.0, 0.0, 1.0};
    
	color[3] = .6;
	CGContextSetStrokeColor(g, color);
	CGContextSetFillColor(g, color);
    
	if (!CGPointEqualToPoint(leftTouch, CGPointZero))
	{
		CGContextFillEllipseInRect(g, dPadLeft);
	} else
	{
		color[3] = .4;
		CGContextSetFillColor(g, color);
		CGContextFillEllipseInRect(g, dPadLeft);
        
		color[3] = .6;
		CGContextSetFillColor(g, color);
	}
    
	if (!CGPointEqualToPoint(rightTouch, CGPointZero))
	{
		CGContextFillEllipseInRect(g, dPadRight);
	} else
	{
		color[3] = .4;
		CGContextSetFillColor(g, color);
		CGContextFillEllipseInRect(g, dPadRight);
        
		color[3] = .6;
		CGContextSetFillColor(g, color);
	}
    
	color[3] = color[0] = 1.0;
	CGContextSetStrokeColor(g, color);
	CGContextSetFillColor(g, color);
    
	if (!CGPointEqualToPoint(leftTouch, CGPointZero))
	{
		CGContextFillEllipseInRect(g, CGRectMake(leftTouch.x - 25, leftTouch.y - 25, 50, 50));
	}
    
	if (!CGPointEqualToPoint(rightTouch, CGPointZero))
	{
		CGContextFillEllipseInRect(g, CGRectMake(rightTouch.x - 25, rightTouch.y - 25, 50, 50));
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (int i = 0; i < [touches count]; i++)
	{
		UITouch *t = [[touches allObjects] objectAtIndex:i];
		CGPoint pt = [t locationInView:self];
        
        CGPoint leftRel = CGPointMake(pt.x - dPadLeft.origin.x - dPadLeft.size.width / 2, pt.y - dPadLeft.origin.y - dPadLeft.size.height / 2);
        CGPoint rightRel = CGPointMake(pt.x - dPadRight.origin.x - dPadRight.size.width / 2, pt.y - dPadRight.origin.y - dPadRight.size.height / 2);
        
		if (sqrtf(powf(leftRel.x, 2) + powf(leftRel.y, 2)) <= dPadLeft.size.width / 2)
        {
			leftTouch = pt;
            
            wasInsideLeft = true;
        }
        
		if (sqrtf(powf(rightRel.x, 2) + powf(rightRel.y, 2)) <= dPadRight.size.width / 2)
        {
			rightTouch = pt;
            
            wasInsideRight = true;
        }
        
        //NSLog(@"Touched: %f, %f    %f, %f", leftRel.x, leftRel.y, rightTouch.x, rightTouch.y);
	}
    
	[self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	for (int i = 0; i < [touches count]; i++)
	{
		UITouch *t = [[touches allObjects] objectAtIndex:i];
		CGPoint pt = [t locationInView:self];
        
		CGPoint leftRel = CGPointMake(pt.x - dPadLeft.origin.x - dPadLeft.size.width / 2, pt.y - dPadLeft.origin.y - dPadLeft.size.height / 2);
        CGPoint rightRel = CGPointMake(pt.x - dPadRight.origin.x - dPadRight.size.width / 2, pt.y - dPadRight.origin.y - dPadRight.size.height / 2);
        
        float leftLen = sqrtf(powf(leftRel.x, 2) + powf(leftRel.y, 2));
        float rightLen = sqrtf(powf(rightRel.x, 2) + powf(rightRel.y, 2));
        
		if (leftLen <= dPadLeft.size.width / 2)
        {
			leftTouch = pt;
            
            wasInsideLeft = true;
        } else if (pt.x < self.frame.size.width / 2 && wasInsideLeft)
        {
            float ratio = leftLen / (dPadLeft.size.width / 2);
            
            leftTouch = CGPointMake(leftRel.x / ratio + dPadLeft.origin.x + dPadLeft.size.width / 2, leftRel.y / ratio + dPadLeft.origin.y + dPadLeft.size.height / 2);
        }
        
		if (rightLen <= dPadRight.size.width / 2)
        {
			rightTouch = pt;
            
            wasInsideRight = true;
        } else if (pt.x > self.frame.size.width / 2 && wasInsideRight)
        {
            float ratio = rightLen / (dPadRight.size.width / 2);
            
            rightTouch = CGPointMake(rightRel.x / ratio + dPadRight.origin.x + dPadRight.size.width / 2, rightRel.y / ratio + dPadRight.origin.y + dPadRight.size.height / 2);
        }
        
        //NSLog(@"Touched: %f, %f    %f, %f", leftTouch.x, leftTouch.y, rightTouch.x, rightTouch.y);
	}
    
	[self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (int i = 0; i < [touches count]; i++)
	{
		UITouch *t = [[touches allObjects] objectAtIndex:i];
		CGPoint pt = [t locationInView:self];
        
        if (pt.x < self.frame.size.width / 2 && wasInsideLeft)
        {
            leftTouch = CGPointZero;
            
            wasInsideLeft = false;
        }
        
        if (pt.x > self.frame.size.width / 2 && wasInsideRight)
        {
            rightTouch = CGPointZero;
            
            wasInsideRight = false;
        }
    }
    
	[self setNeedsDisplay];
}

- (NSArray *)getAxisValues
{
	double leftX = 0, leftY = 0, rightX = 0, rightY = 0;
    
	if (!CGPointEqualToPoint(leftTouch, CGPointZero))
	{
        leftX = (leftTouch.x - (dPadLeft.size.width / 2) - dPadLeft.origin.x) / dPadLeft.size.width;
		leftY = (leftTouch.y - (dPadLeft.size.height / 2) - dPadLeft.origin.y) / dPadLeft.size.height;
        
		leftX *= 2;
		leftY *= -2;
        
		if (leftX > Max) leftX = Max;
		if (leftX < -1) leftX = -1;
        
		if (leftY > Max) leftY = Max;
		if (leftY < -1) leftY = -1;
        
		leftX *= 128;
		leftY *= 128;
	} else
    {
        leftX = 0;
        leftY = 0;
    }
    
	if (!CGPointEqualToPoint(rightTouch, CGPointZero))
	{
        rightX = (rightTouch.x - (dPadRight.size.width / 2) - dPadRight.origin.x) / dPadRight.size.width;
		rightY = (rightTouch.y - (dPadRight.size.height / 2) - dPadRight.origin.y) / dPadRight.size.height;
        
		rightX *= 2;
		rightY *= -2;
        
		if (rightX > Max) rightX = Max;
		if (rightX < -1) rightX = -1;
        
		if (rightY > Max) rightY = Max;
		if (rightY < -1) rightY = -1;
        
		rightX *= 128;
		rightY *= 128;
	} else
    {
        rightX = 0;
        rightY = 0;
    }
    
    return [[NSArray alloc] initWithObjects:[NSNumber numberWithDouble:round(leftX)], [NSNumber numberWithDouble:round(leftY)], [NSNumber numberWithDouble:round(rightX)], [NSNumber numberWithDouble:round(rightY)], nil];
}

@end
