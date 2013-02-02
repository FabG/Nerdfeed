//
//  WebViewController.m
//  Nerdfeed
//
//  Created by Fabrice Guillaume on 1/31/13.
//  Copyright (c) 2013 Fabrice Guillaume. All rights reserved.
//

#import "WebViewController.h"
#import "RSSItem.h"

@implementation WebViewController

- (void)splitViewController:(UISplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc
{
    // If this bar button item doesn't have a title, it won't appear at all.
    [barButtonItem setTitle:@"List"];
    
    // Take this bar button item and put it on the left side of our nav item.
    [[self navigationItem] setLeftBarButtonItem:barButtonItem];
}

- (void)loadView
{
    NSLog(@"WebViewController - loadview)");
    // Create an instance of UIWebView as large as the screen
    CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
    UIWebView *wv = [[UIWebView alloc] initWithFrame:screenFrame];
    
    // Tell web view to scale web content to fit window bounds of webview
    [wv setScalesPageToFit:YES];
    
    [self setView:wv];
}

- (UIWebView *)webView
{
    NSLog(@"[WVC] webview");
    return (UIWebView *)[self view];
}

// Allow rotation if user is running on iPad (pre-iOS6)
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)io
{
    NSLog(@"[WVC] shouldAutorotateToInterfaceOrientation");
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return YES;
    return io == UIInterfaceOrientationPortrait;
}

// When one of the rows is tapped in the table view, the ListViewController will send the
// listViewController:handleObject message to the WebViewController
// implementing it
- (void)listViewController:(ListViewController *)lvc handleObject:(id)object
{
    // Cast the passed object to RSSItem
    RSSItem *entry = object;
    
    // Make sure that we are really gettig a RSSItem
    if (![entry isKindOfClass:[RSSItem class]])
          return;
    
    NSLog(@"[WVC] message received from LVC - received objected is of class RSSItem");
    // Grab the info from the item and push it into the appropriate views
    NSURL *url = [NSURL URLWithString:[entry link]];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    [[self webView] loadRequest:req];
    
    [[self navigationItem] setTitle:[entry title]];
}

- (void) splitViewController:( UISplitViewController *) svc
      willShowViewController:( UIViewController *) aViewController
   invalidatingBarButtonItem:( UIBarButtonItem *) barButtonItem
{
    // Remove the bar button item from our navigation item
    // We'll double check that its the correct button, even though we know it is
    if (barButtonItem == [[ self navigationItem] leftBarButtonItem])
        [[ self navigationItem] setLeftBarButtonItem:nil]; }
    

@end
