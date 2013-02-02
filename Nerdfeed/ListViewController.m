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

@implementation ListViewController

@synthesize webViewController;

// stubs for the required data source methods
- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"[LVC] number of Row : %i", [[channel items] count]);
    return [[channel items] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
        UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
    }
    RSSItem *item = [[channel items] objectAtIndex:[indexPath row]];
    [[cell textLabel] setText:[item title]];
    
    NSLog(@"[LVC] title : %@", [item title]);

    return cell;
}

// method to create a NSURLRequest and a connection
- (void)fetchEntries
{
    // Create a new data container for the suff that comes back from the service
    xmlData = [[NSMutableData alloc]init];
    
    // Construt a URL that will ask the service for what you want
    // note we can concatenate literal strings together on multiple lines
    // in this way - this results in a single NSString instance
    NSURL *url = [NSURL URLWithString:@"http://forums.bignerdranch.com/smartfeed.php?"
                  @"limit=1_DAY&sort_by=standard&feed_type=RSS2.0&feed_style=COMPACT"];
    
    //For Apple's Hot News feed, replace the line aboce with
    //NSURL *url = [NSURL URLWithString:@"http://www.apple.com/pr/eeds/pr.rss"];
    
    // Put that URL into an NSURLRequest
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    
    // Create a connection that will exchange this request for data from the URL
    connection = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES];
    NSLog(@"fetching data from %@", [url absoluteString]);

}

// override initWithStyle to kick off the exchange whenever the ListViewcontroller is created
- (id)initWithStyle:(UITableViewStyle)style
{
    NSLog(@"[LVC] initWithStyle");
    self = [super initWithStyle:style];
    if (self) {
        // Add UIbarButtonItem to the ListViewController's navigation Item
        // to display RSSChannel
        UIBarButtonItem *bbi=
            [[UIBarButtonItem alloc] initWithTitle:@"Info"
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(showInfo:)];
        
        [[self navigationItem] setRightBarButtonItem:bbi];
        
        [self fetchEntries];
    }
    return self;
}

// The delegate of NSURLConnection is responsible for overseing the connection and for collecting the data
// return form the request (XML or Jason - in this case: XML). However the data comes back in pieces.
// implementing delegate's method to put the pieces together
// This method will be called several times as the data arrives
- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
{
    // Add the incoming chunk of data to the container we are keeping
    // The data will always comes in the correct order
    [xmlData appendData:data];
    
    NSLog(@"connection:didReceiveData");
}

// When a connection has finished retrieveing all the data form the webservie, it sends the below method
// to its deledate - implementing it
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // We are just checking to make sure we are getting the XML
    //NSString *xmlCheck = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
    //NSLog(@"xmlCheck = %@", xmlCheck);
    
    // Create the parser object with the data received from the web service
    NSXMLParser *parser = [[NSXMLParser alloc]initWithData:xmlData];
    
    // Give it a delegate
    [parser setDelegate:self];
    
    // Tell it to start parsing - the document will be parsed and the deledate of NSXMLParser
    // will get of its delegate messages sent to it before this line finishes execution
    // It is blocking
    [parser parse];
    
    // Get rid of the XML data as we no longer need it
    xmlData = nil;
    
    // Get rid of the connection
    connection = nil;
    
    // Reload the table.. for now it will be empty
    [[self tableView] reloadData];
    //NSLog(@"%@\n %@\n%@\n", channel, [channel title], [channel infoString]);
    
}


// implement connection:DidFailWithError to catch dailures such as having no Internet or if server odes not exist
// Note that other types of errors (such as wrong format,...) are also sent via connection:didReceiveData
- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
    // Release the connection object, we're done with it
    connection = nil;
    
    // Release the xmlData object
    xmlData = nil;
    
    // Grab the description of the error bject passed to us
    NSString *errorString = [NSString stringWithFormat:@"Fetch failed: %@", [error localizedDescription]];
    
    // Create and show an alert view with this error displayed
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
                        
}

// implement NSXMLParserDelegate method to cate the start of a "channel" element
- (void)parser:(NSXMLParser *)parser
    didStartElement:(NSString *)elementName
    namespaceURI:(NSString *)namespaceURI
    qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict
{
    NSLog(@"[LVC] %@ found a %@ element", self, elementName);
    if ([elementName isEqual:@"channel"]) {
        // if the parser saw a channel, create a new instance, store in our ivar
        channel = [[RSSChannel alloc]init];
        NSLog(@"[LVC] Creating Channel object");
        
        // Give the channel object a pointer back to ourselves for later
        [channel setParentParserDelegate:self];
        
        // Set the parser's delegate to the channel object
        [parser setDelegate:channel];
        NSLog(@"[LVC] Channel is now parser's delegate");
        
    }
}

// When user taps on a row in the table view, we want the WebViewController to be pushed onto
// the navigation stack and the link for the selected RSSItem to be loade into its web view
- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"[LVC] didSelectRowAtIndexPath");
    // Push the web view controller
    // add a check on split view controller before pushing the WebViewController
    // for iPad landscape mode where we will have the list on a separate view
    if (![self splitViewController])
    {
        NSLog(@"Pushing webViewController onto existing navigationController");
        [[self navigationController] pushViewController:webViewController animated:YES];
    }
    else {

        // We have to create a new navigation controller, as the old one
        // was only retained by the split view controller and is now gone
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:webViewController];
        NSLog(@"Creating and Pushing new webViewController");
        
        NSArray *vcs = [NSArray arrayWithObjects:[self navigationController], nav, nil];
        
        [[self splitViewController]setViewControllers:vcs];
        
        // Make the detail view controller the delegate of the split view controller
        [[self splitViewController] setDelegate:webViewController];
        
    }
    // Grab the selected item
    RSSItem *entry = [[channel items] objectAtIndex:[indexPath row]];
    
    
    // send the listViewController:handleObject message to WebViewController
    [webViewController listViewController:self handleObject:entry];
    
}

// Allow rotation if user is running on iPad (pre-iOS6)
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)io
{
    NSLog(@"[LVC] shouldAutorotateToInterfaceOrientation");
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return YES;
    return io == UIInterfaceOrientationPortrait;
}

// When the button is tapped, the detail view controller in the split view will be replaced with
// an instance of ChannelViewController.
- (void)showInfo:(id)sender
{
    NSLog(@"[LVC] button tapped -> showinfo");
    // Create the channel view controller
    ChannelViewController *channelViewController = [[ChannelViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    if ([self splitViewController]) {
        UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:channelViewController];
        
        // Create an array with our nav controller and this new VS's nav controller
        NSArray *vcs = [NSArray arrayWithObjects:[self navigationController], nvc, nil];
        
        // Grab a pointer to the split view controller
        // and reset its view controllers array
        [[self splitViewController] setViewControllers:vcs];
        
        // Make detail view controller the delegate of the split view controller
        [[self splitViewController] setDelegate:channelViewController];
        
        // If a row has been selected, deselect it so that a row
        // is not selected when viewing the info
        NSIndexPath *selectedRow = [[self tableView] indexPathForSelectedRow];
        if (selectedRow)
            [[self tableView] deselectRowAtIndexPath:selectedRow animated:YES];
        
    } else {
        [[self navigationController] pushViewController:channelViewController animated:YES];
    }
    
    // give the VC the channel object through the protocol message
    [channelViewController listViewController:self handleObject:channel];
}

@end
