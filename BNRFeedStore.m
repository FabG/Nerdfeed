//
//  BNRFeedStore.m
//  Nerdfeed
//
//  Created by Fabrice Guillaume on 2/2/13.
//  Copyright (c) 2013 Fabrice Guillaume. All rights reserved.
//

#import "BNRFeedStore.h"
#import "RSSChannel.h"
#import "BNRConnection.h"

// STORE to handle connections: BNRFeedStore will be a singleton
// All controllers access the same instance of BNRFeedStore
@implementation BNRFeedStore

+ (BNRFeedStore *)sharedStore
{
    static BNRFeedStore *feedStore = nil;
    
    if (!feedStore)
        feedStore = [[BNRFeedStore alloc]init];
    
    return feedStore;
}

// Store (block)
// Takes two arguments: a pointer to an RSSChannel and a pointer to an NSError object. If the request was a
// success, the RSSChannel will be passed as an argument, and the NSError will be nil. If there was a problem,
// an instance of NSError will be passed as an argument, and the RSSChannel will be nil.
- (void)fetchRSSFeedWithCompletion:(void (^)(RSSChannel *, NSError *))block
{
    NSURL *url = [NSURL URLWithString:@"http://forums.bignerdranch.com/"
                  @"smartfeed.php?limit=1_DAY&sort_by=standard"
                  @"&feed_type=RSS2.0&feed_style=COMPACT"];
    
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    
    // Create an empty channel
    RSSChannel *channel = [[RSSChannel alloc]init];
    
    // Create a connection "actor" object that will transfer data from the server
    BNRConnection *actorConnection = [[BNRConnection alloc] initWithRequest:req];
    
    // When the connection completes, this block from the controller will be called
    [actorConnection setCompletionBlock:block];
    
    // Let the empty channel parse the returning data from the web service
    [actorConnection setXmlRootObject:channel];
    
    // Begin the connection
    [actorConnection start];
}


@end