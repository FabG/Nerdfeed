//
//  BNRConnection.m
//  Nerdfeed
//
//  Created by Fabrice Guillaume on 2/2/13.
//  Copyright (c) 2013 Fabrice Guillaume. All rights reserved.
//

#import "BNRConnection.h"

static NSMutableArray *sharedConnectionList = nil;  // to keep a strong reference to all active BNRConnections

// BNRConnection will be an actor (Actor Design Pattern) from the BNRFeedStore
// to handle long running query and execute call back from ListViewController

// For every request, the BNRFeedStore makes, it will create an instance of BNRConnection
// An instance of this class is a one-shot deal: it runs, it calls back and then it is destroyed
@implementation BNRConnection 
@synthesize request, completionBlock, xmlRootObject;

// An instance of BNRConnection, when started, will create an instance of NSURLConnection,
// initialize it with NSURLRequest and set itself as a delegate of that connection

- (id) initWithRequest:(NSURLRequest *)req
{
    self = [super init];
    if (self) {
        [self setRequest:req];
    }
    return self;
}

- (void)start
{
    // Initialize container for data collected from NSURLConnection
    dataContainer = [[NSMutableData alloc]init];
    
    // Spawn connection and set BNRConnection as delegate
    internalConnection = [[NSURLConnection alloc] initWithRequest:[self request]
                                                         delegate:self
                                                 startImmediately:YES];
    
    // If this is the first connection started, create the array
    if (!sharedConnectionList)
        sharedConnectionList = [[NSMutableArray alloc]init];
    
    // Add the connection to the array so it doesn't get destroyed
    [sharedConnectionList addObject:self];
    
}

// BNRConnection is the delegate of NSURLConnection, soit needs to implement the delegate methods
// for NSURLConnection that retrieve the data and report success or failure
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [dataContainer appendData:data];
    
}

// The BNRConnection will hold on to all of the data that returns from the web service. When that
// web service completes successfully, it must first parse that data into the xmlRootObject and then
// call the completionBlock. Finally, it needs to take itself out of the array of active connections
// so that it can be destroyed.
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Create a parser with the incoming data and let the root object parse its contents
    NSXMLParser *parser = [[NSXMLParser alloc]initWithData:dataContainer];
    [parser setDelegate:[self xmlRootObject]];
    [parser parse];
    
    // Then pass the root object to the completion block - block supplied by the controller
    if ([self completionBlock])
        [self completionBlock] ([self xmlRootObject], nil);
    
    // Now destroy this connection
    [sharedConnectionList removeObject:self];
}

// If there is a problem with the connection, the completion block is called without the root object
// and an error object is passed instead. 
- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // Pass the error from the connection to the completionBlock
    if ([self completionBlock])
        [self completionBlock] (nil,error);
    
    // Destroy this connection
    [sharedConnectionList removeObject:self];
}


@end