//
//  ListViewController.m
//  Nerdfeed
//
//  Created by Fabrice Guillaume on 1/30/13.
//  Copyright (c) 2013 Fabrice Guillaume. All rights reserved.
//

#import "ListViewController.h"

@implementation ListViewController

// stubs for the required data source methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
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
    self = [super initWithStyle:style];
    if (self) {
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
    NSString *xmlCheck = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
    NSLog(@"xmlCheck = %@", xmlCheck);
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


@end