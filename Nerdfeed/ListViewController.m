//
//  ListViewController.m
//  Nerdfeed
//
//  Created by Fabrice Guillaume on 1/30/13.
//  Copyright (c) 2013 Fabrice Guillaume. All rights reserved.
//

#import "ListViewController.h"
#import "RSSChannel.h"
#import "RSSItem.h"
#import "WebViewController.h"
#import "ChannelViewController.h"
#import "BNRFeedStore.h"

@interface ListViewController ()
- (void)transferBarButtonToViewController:(UIViewController *)vc;
@end

@implementation ListViewController
@synthesize webViewController;

- (void)transferBarButtonToViewController:(UIViewController *)vc
{
    // Get the navigation controller in the detail spot of the split view controller
    UINavigationController *nvc = [[[self splitViewController] viewControllers]
                                   objectAtIndex:1];
    
    // Get the root view controller out of that nav controller
    UIViewController *currentVC = [[nvc viewControllers] objectAtIndex:0];
    
    // If it's the same view controller, let's not do anything
    if (vc == currentVC)
        return;
    
    // Get that view controller's navigation item
    UINavigationItem *currentVCItem = [currentVC navigationItem];
    
    // Tell new view controller to use left bar button item of current nav item
    [[vc navigationItem] setLeftBarButtonItem:[currentVCItem leftBarButtonItem]];
    
    // Remove the bar button item from the current view controller's nav item
    [currentVCItem setLeftBarButtonItem:nil];
}
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    
    if (self) {
        [self fetchEntries];
        UIBarButtonItem *bbi =
        [[UIBarButtonItem alloc] initWithTitle:@"Info"
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(showInfo:)];
        
        [[self navigationItem] setRightBarButtonItem:bbi];
        
    }
    
    return self;
}

- (void)showInfo:(id)sender
{
    // Create the channel view controller
    ChannelViewController *channelViewController = [[ChannelViewController alloc]
                                                    initWithStyle:UITableViewStyleGrouped];
    
    if ([self splitViewController]) {
        [self transferBarButtonToViewController:channelViewController];
        
        UINavigationController *nvc = [[UINavigationController alloc]
                                       initWithRootViewController:channelViewController];
        
        // Create an array with our nav controller and this new VC's nav controller
        NSArray *vcs = [NSArray arrayWithObjects:[self navigationController],
                        nvc,
                        nil];
        
        // Grab a pointer to the split view controller
        // and reset its view controllers array.
        [[self splitViewController] setViewControllers:vcs];
        
        // Make detail view controller the delegate of the split view controller
        [[self splitViewController] setDelegate:channelViewController];
        
        // If a row has been selected, deselect it so that a row
        // is not selected when viewing the info
        NSIndexPath *selectedRow = [[self tableView] indexPathForSelectedRow];
        if (selectedRow)
            [[self tableView] deselectRowAtIndexPath:selectedRow animated:YES];
    } else {
        [[self navigationController] pushViewController:channelViewController
                                               animated:YES];
    }
    
    // Give the VC the channel object through the protocol message
    [channelViewController listViewController:self handleObject:channel];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)io
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return YES;
    return io == UIInterfaceOrientationPortrait;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Push the web view controller onto the navigation stack - this implicitly
    // creates the web view controller's view the first time through
    if (![self splitViewController])
        [[self navigationController] pushViewController:webViewController animated:YES];
    else {
        [self transferBarButtonToViewController:webViewController];
        // We have to create a new navigation controller, as the old one
        // was only retained by the split view controller and is now gone
        UINavigationController *nav =
        [[UINavigationController alloc] initWithRootViewController:webViewController];
        
        NSArray *vcs = [NSArray arrayWithObjects:[self navigationController],
                        nav,
                        nil];
        
        [[self splitViewController] setViewControllers:vcs];
        
        // Make the detail view controller the delegate of the split view controller
        [[self splitViewController] setDelegate:webViewController];
    }
    // Grab the selected item
    RSSItem *entry = [[channel items] objectAtIndex:[indexPath row]];
    
    [webViewController listViewController:self handleObject:entry];
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return [[channel items] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView
                             dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:@"UITableViewCell"];
    }
    RSSItem *item = [[channel items] objectAtIndex:[indexPath row]];
    [[cell textLabel] setText:[item title]];
    
    return cell;
}

// New code leveraging our store to fetch entriess
- (void)fetchEntries
{
    // Initiate the request
    [[BNRFeedStore sharedStore] fetchRSSFeedWithCompletion:^( RSSChannel *obj, NSError *err) {
        
        // when the request completes, this block will be called
        if (!err) {
            // if everything went ok, grab the channel object, and reload the table
            channel = obj;
            [[self tableView] reloadData];
            
        } else {
            // if things went bad, show an alert view
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:[err localizedDescription]
                                                    delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles: nil];
            [av show];
        }
        
    }];
}
@end