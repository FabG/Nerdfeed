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
@synthesize jsonRootObject;

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
    NSLog(@"\t\t[BNRCnction] start");
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
    //NSLog(@"\t\t[BNRCnction] connection didReceiveData");
    [dataContainer appendData:data];
    
}

// The BNRConnection will hold on to all of the data that returns from the web service. When that
// web service completes successfully, it must first parse that data into the xmlRootObject and then
// call the completionBlock. Finally, it needs to take itself out of the array of active connections
// so that it can be destroyed.
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    id rootObject = nil;
    
    NSLog(@"\t\t[BNRCnction] connectionDidFinishLoading");
    
    // Create a parser with the incoming data and let the root object parse its contents
    // Check if it is XML or JSON
    if ([self xmlRootObject]) {
        NSXMLParser *parser = [[NSXMLParser alloc]initWithData:dataContainer];
        [parser setDelegate:[self xmlRootObject]];
        [parser parse];
        
        rootObject = [self xmlRootObject];
    } else if ([self jsonRootObject]) {
        // turn JSON data into a basic model objects
        NSDictionary *d = [NSJSONSerialization JSONObjectWithData:dataContainer
                                                           options:0
                                                             error:nil];
        
        // Have the root object construct itself from basic model objects
        [[self jsonRootObject] readFromJSONDictionary:d];
        
        rootObject = [self jsonRootObject];
    }
    
    // Then pass the root object to the completion block - block supplied by the controller
    if ([self completionBlock])
        [self completionBlock] (rootObject, nil);
    
    // Now destroy this connection
    [sharedConnectionList removeObject:self];
}

// If there is a problem with the connection, the completion block is called without the root object
// and an error object is passed instead. 
- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"\t\t[BNRCnction] connection didFailWithError");
    // Pass the error from the connection to the completionBlock
    if ([self completionBlock])
        [self completionBlock](nil, error);
    
    // Destroy this connection
    [sharedConnectionList removeObject:self];
}


@end
