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

        UIBarButtonItem *bbi =
        [[UIBarButtonItem alloc] initWithTitle:@"Info"
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(showInfo:)];
        
        [[self navigationItem] setRightBarButtonItem:bbi];
        
        // Add a UISegmentedControl to the navigationItem that will change the rssType.
        UISegmentedControl *rssTypeControl = [[ UISegmentedControl alloc] initWithItems: [NSArray arrayWithObjects:@" BNR", @" Apple", nil]];
        [rssTypeControl setSelectedSegmentIndex: 0];
        [rssTypeControl setSegmentedControlStyle:UISegmentedControlStyleBar];
        [rssTypeControl addTarget:self action:@ selector( changeType:) forControlEvents:UIControlEventValueChanged];
        [[ self navigationItem] setTitleView:rssTypeControl];
        
        
        [self fetchEntries];

    }
    
    return self;
}

// Implement changeType:, which will be sent to the ListViewController when the segmented control changes.
- (void)changeType:(id)sender
{
    NSLog(@"[LVC] changeType");
    rssType = [sender selectedSegmentIndex];
    [self fetchEntries];
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
// with the addition of iTunes RSSfeed, make the appropriate request to the store depending on the
// current rssType. To do this, move the completion block into a local variable, and then pass it
// to the right store request method.
- (void)fetchEntries
{
    // Get ahold of the segmented control that is currently in the title view
    UIView *currentTitleView = [[self navigationItem] titleView];
    
    // Create a loading indicator and start it spinning in the nav bar
    UIActivityIndicatorView *aiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [[self navigationItem]setTitleView:aiView];
    [aiView startAnimating];
    

    NSLog(@"[LVC] fetchEntries");
    void (^completionBlock) (RSSChannel *obj, NSError *err) =
    ^(RSSChannel *obj, NSError *err) {
        // When the request completes, this block will be called
        NSLog(@"[LVC] completion Block called!");
        
        // replace the indicator with the segmented control
        [[self navigationItem] setTitleView:currentTitleView];
        
        if (!err) {
            // if everything went ok, grab the channel object, and reload the table
            channel = obj;
            NSLog(@"[LVC] tableView reloadData");
            [[self tableView] reloadData];
            
        } else {
            NSLog(@"[LVC] Error...");
            // if things went bad, show an alert view
            NSString *errorString = [NSString stringWithFormat:@" Fetch failed: %@",
                                     [err localizedDescription]];
            
            // Create and show an alert view with this error displayed
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:errorString
                                                    delegate:nil
                                                    cancelButtonTitle:@"OK"
                                                    otherButtonTitles: nil];
            [av show];
        }
    };
    
    // Initiate the request
    if (rssType == ListViewControllerRSSTypeBNR)
    {
        NSLog(@"[LVC] BNR Request");
        channel = [[BNRFeedStore sharedStore]
                   fetchRSSFeedWithCompletion:^(RSSChannel *obj, NSError *err) {
            // replace the activity indicator
            [[self navigationItem] setTitleView:currentTitleView];
            
            if (!err) {
                // How many items are there currently?
                int currentItemCount = [[channel items]count];
                
                // Set out channel to the merged one
                channel = obj;
                
                // How many items are there now?
                int newItemCount = [[channel items]count];
                
                // For each new item, insert a new row. The data source
                // will take care of the rest.
                int itemDelta = newItemCount - currentItemCount;
                if (itemDelta > 0)
                {
                    NSMutableArray * rows = [NSMutableArray array];
                    for (int i = 0; i < itemDelta; i++) {
                        NSIndexPath *ip = [NSIndexPath indexPathForRow:i
                                                             inSection:0];
                        [rows addObject:ip];
                    }
                    
                    [[self tableView] insertRowsAtIndexPaths:rows
                                            withRowAnimation:UITableViewRowAnimationTop];
                }
            }
        }];
        
        [[self tableView] reloadData];
    }
    else if (rssType == ListViewControllerRSSTypeApple)
    {
        NSLog(@"[LVC] Apple Request");
        [[BNRFeedStore sharedStore] fetchTopSongs:10 withCompletion:completionBlock];
    }
    
    NSLog(@"[LVC] Executing code at the end of fetchEntries");
    
}
@end