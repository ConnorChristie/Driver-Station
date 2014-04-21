//
//  DriverStationTableViewController.m
//  Driver Station
//
//  Created by Connor on 3/24/14.
//  Copyright (c) 2014 Connor Christie. All rights reserved.
//

#import "DriverStationTableViewController.h"

#import "AppDelegate.h"

@interface DriverStationTableViewController ()
{
    AppDelegate *delegate;
}

@end

@implementation DriverStationTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    delegate = [[UIApplication sharedApplication] delegate];
    
    NSTimer *sender = [NSTimer timerWithTimeInterval:.019 target:self selector:@selector(updateAndSend) userInfo:nil repeats:YES];
    
	[[NSRunLoop currentRunLoop] addTimer:sender forMode:NSDefaultRunLoopMode];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)updateAndSend
{
    [self updateUI];
    
    //Send out the data
}

- (void)updateUI
{
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 2;
    } else if (section == 1)
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
    }
    
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    switch (indexPath.section)
    {
        case 0:
            if (indexPath.row == 0)
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"Team Number"];
            } else
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"Info"];
                
                cell.detailTextLabel.text = [NSString stringWithFormat:@"10.%i.%i.2", delegate.teamNumber / 100, delegate.teamNumber % 100];
                
                //[Utilities setShort:&toRobotData.teamID value:delegate.teamNumber];
            }
            
            break;
        case 1:
            if (delegate.state == RobotNotConnected)
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"Not Connected"];
                
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            } else
            {
                cell = [tableView dequeueReusableCellWithIdentifier:@"Control"];
                
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                
                UILabel *textLabel = (UILabel *) [cell viewWithTag:2];
                //UISegmentedControl *control = (UISegmentedControl *) [cell viewWithTag:1];
                
                if (delegate.state == RobotDisabled)
                {
                    textLabel.text = @"Enable";
                    textLabel.textColor = [UIColor colorWithRed:0 green:207 / 255.0f blue:65 / 255.0f alpha:1];
                } else if (delegate.state == RobotEnabled)
                {
                    textLabel.text = @"Disable";
                    textLabel.textColor = [UIColor redColor];
                }
            }
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    if (indexPath.section == 1)
    {
        if ((delegate.state & RobotDisabled) == RobotDisabled)
        {
            delegate.state = (delegate.state & ~RobotDisabled) | RobotEnabled;
        } else if ((delegate.state & RobotEnabled) == RobotEnabled)
        {
            delegate.state = (delegate.state & ~RobotEnabled) | RobotDisabled;
        }
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
        UILabel *textLabel = (UILabel *) [cell viewWithTag:2];
        
        if ((delegate.state & RobotDisabled) == RobotDisabled)
        {
            textLabel.text = @"Enable";
            textLabel.textColor = [UIColor colorWithRed:0 green:207 / 255.0f blue:65 / 255.0f alpha:1];
        } else if ((delegate.state & RobotEnabled) == RobotEnabled)
        {
            textLabel.text = @"Disable";
            textLabel.textColor = [UIColor redColor];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    delegate.teamNumber = [textField.text intValue];
    
    [self.tableView reloadData];
    
    return false;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
