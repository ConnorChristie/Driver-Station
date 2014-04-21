//
//  StatusViewController.m
//  Driver Station
//
//  Created by Connor on 3/26/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import "StatusViewController.h"

#import "AppDelegate.h"
#import "ControlTableViewCell.h"
#import "MainViewController.h"

#import <objc/message.h>

static short ENABLED_BIT    = 0x20;
static short AUTONOMOUS_BIT = 0x50;
static short TELEOP_BIT     = 0x40;

@interface StatusViewController ()
{
    AppDelegate *delegate;
}

@end

@implementation StatusViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    delegate = [[UIApplication sharedApplication] delegate];
}

- (void)viewDidAppear:(BOOL)animated
{
    UIDeviceOrientation before = [[UIDevice currentDevice] orientation];
    
    if (UIInterfaceOrientationIsPortrait(before))
    {
        objc_msgSend([UIDevice currentDevice], @selector(setOrientation:), UIInterfaceOrientationPortraitUpsideDown);
        objc_msgSend([UIDevice currentDevice], @selector(setOrientation:), before);
    } else
    {
        objc_msgSend([UIDevice currentDevice], @selector(setOrientation:), UIInterfaceOrientationPortrait);
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    ((MainViewController *) self.parentViewController).currentIndex = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 1;
    } else if (section == 1)
    {
        return 3;
    } else if (section == 2)
    {
        return 1;
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return @"Robot Info";
    } else if (section == 1)
    {
        return @"Robot Status";
    }
    
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    switch (indexPath.section)
    {
        case 0:
        {
            if (indexPath.row == 0)
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"Team Number"];
            
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%i", delegate.teamNumber];
            }
            
            break;
        }
        case 1:
            if (indexPath.row == 0)
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"Info"];
                
                struct RobotDataPacket *data = [((MainViewController *) self.parentViewController) getInputPacket];
                
                if (delegate.state == RobotNotConnected)
                {
                    data->batteryVolts = 0;
                    data->batteryMV    = 0;
                }
                
                cell.textLabel.text = @"Battery";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2X.%.2XV", data->batteryVolts,  data->batteryMV];
            } else if (indexPath.row == 1)
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"Info"];
                
                cell.textLabel.text = @"Status";
                
                cell.detailTextLabel.textColor = [UIColor grayColor];
                
                switch (delegate.state)
                {
                    case RobotNotConnected:
                        cell.detailTextLabel.text = @"Not Connected";
                        
                        break;
                    case RobotWatchdogNotFed:
                        cell.detailTextLabel.text = @"Watchdog Not Fed";
                        
                        break;
                    case RobotDisabled:
                        cell.detailTextLabel.text = @"Disabled";
                        
                        cell.detailTextLabel.textColor = [UIColor redColor];
                        
                        break;
                    case RobotEnabled:
                        cell.detailTextLabel.text = @"Enabled";
                        
                        cell.detailTextLabel.textColor = [UIColor colorWithRed:0 green:207 / 255.0f blue:65 / 255.0f alpha:1];
                        
                        break;
                    case RobotAutonomous:
                        cell.detailTextLabel.text = @"Autonomous";
                        
                        break;
                }
            }/* else if (indexPath.row == 2)
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"Info"];
                
                cell.textLabel.text = @"Bluetooth";
                cell.detailTextLabel.text = ((MainViewController *)self.parentViewController).blueConnected ? @"Connected" : @"Not Connected";
            } */else if (indexPath.row == 2)
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"Alliance"];
                
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
                UISegmentedControl *color = (UISegmentedControl *) [cell viewWithTag:1];
                UISegmentedControl *index = (UISegmentedControl *) [cell viewWithTag:2];
                
                if (color.selectedSegmentIndex == 0)
                {
                    [color setTintColor:[UIColor redColor]];
                } else
                {
                    [color setTintColor:[UIColor blueColor]];
                }
                
                ((MainViewController *) self.parentViewController).teamColor = color.selectedSegmentIndex;
                ((MainViewController *) self.parentViewController).teamIndex = index.selectedSegmentIndex;
            }
            
            break;
        case 2:
            if (delegate.state == RobotNotConnected)
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"Not Connected"];
                
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            } else
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"Control"];
                
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                
                UILabel *textLabel = (UILabel *) [cell viewWithTag:2];
                UISegmentedControl *control = (UISegmentedControl *) [cell viewWithTag:1];
                
                [control addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
                
                if (delegate.state == RobotDisabled)
                {
                    textLabel.text = @"Enable";
                    textLabel.textColor = [UIColor colorWithRed:0 green:207 / 255.0f blue:65 / 255.0f alpha:1];
                    
                    cell.backgroundColor = [UIColor whiteColor];
                } else if (delegate.state == RobotEnabled || delegate.state == RobotWatchdogNotFed || delegate.state == RobotAutonomous)
                {
                    textLabel.text = @"Disable";
                    textLabel.textColor = [UIColor redColor];
                    
                    cell.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.2];
                }
            }
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    if (indexPath.section == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Edit Team Number" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        
        UITextField *field = [alert textFieldAtIndex:0];
        
        field.text = [NSString stringWithFormat:@"%i", delegate.teamNumber];
        
        [alert show];
    } else if (indexPath.section == 2)
    {
        struct FRCCommonControlData *data = [((MainViewController *) self.parentViewController) getOutputPacket];
        
        if (delegate.state == RobotDisabled)
        {
			data->control += ENABLED_BIT;//(index == 0 ? 0x53 : 0x43) + 0x20;
        } else if (delegate.state == RobotEnabled || delegate.state == RobotWatchdogNotFed || delegate.state == RobotAutonomous)
        {
			data->control -= ENABLED_BIT;//(index == 0 ? 0x53 : 0x43) - 0x20;
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        UITextField *field = [alertView textFieldAtIndex:0];
        
        if ([field.text intValue] != delegate.teamNumber)
        {
            delegate.teamNumber = [field.text intValue];
            
            [((MainViewController *) self.parentViewController) changeTeam];
        }
    }
}

- (void)segmentChanged:(id)sender
{
    int index = [self controlIndex];
    
    if (delegate.state != RobotNotConnected)
    {
        struct FRCCommonControlData *data = [((MainViewController *) self.parentViewController) getOutputPacket];
        
        if (index == 0)
        {
            data->control = AUTONOMOUS_BIT;
        } else
        {
            data->control = TELEOP_BIT;
        }
    }
}

- (int)controlIndex
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
    
    if ([cell isKindOfClass:[ControlTableViewCell class]])
    {
        return (int) ((ControlTableViewCell *) [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]]).control.selectedSegmentIndex;
    }
    
    return 0;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
