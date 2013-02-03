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

// We need this date to persist between runs of the application, so it needs to be stored
// on the filesystem. Since this is just a little bit of data, we won’t create a separate
// file for it. Instead, we’ll just put it in NSUserDefaults. To do this, we have to write
// our own implementations of topSongsCacheDate’s accessor methods instead of synthesizing
// the property.
- (void)setTopSongsCacheDate:(NSDate *)topSongsCacheDate
{
    [[NSUserDefaults standardUserDefaults] setObject:topSongsCacheDate forKey:@"topSongsCacheDate"];
}

- (NSDate *)topSongsCacheDate
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"topSongsCacheDate"];
}

// Store (block)
// Takes two arguments: a pointer to an RSSChannel and a pointer to an NSError object. If the request was a
// success, the RSSChannel will be passed as an argument, and the NSError will be nil. If there was a problem,
// an instance of NSError will be passed as an argument, and the RSSChannel will be nil.
- (void)fetchRSSFeedWithCompletion:(void (^)(RSSChannel *, NSError *))block
{
    NSLog(@"\t[BNRStore] fetchRSSFeedWithCompletion block");
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
    NSLog(@"\t[BNRStore] actorConnection start");
    [actorConnection start];
    
}

// Store (block) for iTunes:
// method to fetch data from iTunes with an argument on the number of top songs
- (void) fetchTopSongs:(int)count
        withCompletion:(void (^)(RSSChannel *, NSError *))block
{
    // Construct the cache path
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    cachePath = [cachePath stringByAppendingPathComponent:@"apple.archive"];
    
    // Make sure we have cached at least once before checking to see if this date exist
    NSDate *tscDate = [self topSongsCacheDate];
    if (tscDate) {
        // How old is the cache?
        NSTimeInterval cacheAge = [tscDate timeIntervalSinceNow];
        
        if (cacheAge > -300.0) {
            // If this is less than 300 seconds (5mn) old, return cache
            // in completion block
            NSLog(@"\t[BNRStore] Reading cache!");
            
            RSSChannel *cachedChannel = [NSKeyedUnarchiver unarchiveObjectWithFile:cachePath];
            
            if (cachedChannel) {
                // Insert completion block as the NEXT event in the run loop instead
                // of being called immediately
                [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                    // Execute the controller's completion block to reload its table
                    block(cachedChannel, nil);
                }];
                
                // Don't need to make the request, just get out of this method
                return;
            }
            
        }
    }
        
    NSLog(@"\t[BNRStore] fetchTopSongs:withCompletion block");
    // Prepare a request URL, including the argument from the controller
    // Moving from XML to JSON
    //NSString *requestString = [NSString
    //        stringWithFormat:@"http://itunes.apple.com/us/rss/topsongs/limit=%d/xml", count];
    NSString *requestString = [NSString
                               stringWithFormat:@"http://itunes.apple.com/us/rss/topsongs/limit=%d/json", count];
    
    NSURL *url = [NSURL URLWithString:requestString];
    
    // Set up the connection as normal
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    RSSChannel *channel = [[RSSChannel alloc] init];
    
    // Create a connection "actor" object that will transfer data from the server
    BNRConnection *connection = [[BNRConnection alloc] initWithRequest:req];
    
    //update the completion block for the store to run its code (to take care of caching)
    // and then execute the completion block from the controller
    [connection setCompletionBlock:^(RSSChannel *obj, NSError *err) {
        // This is the store's completion code:
        // If everything went smoothly, save the channel to disk and set cache date
        if (!err) {
            [self setTopSongsCacheDate:[NSDate date]];
            [NSKeyedArchiver archiveRootObject:obj toFile:cachePath];
        }
        
        // This is the Controler's completion code
        block(obj,err);
    }];
    
    
    //[connection setXmlRootObject:channel];
    [connection setJsonRootObject:channel];
    
    // Begin the connection
    NSLog(@"\t[BNRStore] actorConnection start");
    [connection start];
}

@end
