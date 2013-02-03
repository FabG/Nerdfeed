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
#import "RSSItem.h"

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

// init method to create the appropriate objects for Core Data to work.
- (id)init
{
    self = [super init];
    if (self) {
        model = [NSManagedObjectModel mergedModelFromBundles:nil];
        
        NSPersistentStoreCoordinator *psc =
            [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
        
        NSError *error = nil;
        NSString *dbPath =
            [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                 NSUserDomainMask,
                                                 YES)objectAtIndex:0];
        dbPath = [dbPath stringByAppendingPathComponent:@"feed.db"];
        NSURL *dbURL = [NSURL fileURLWithPath:dbPath];
        
        if (![psc addPersistentStoreWithType:NSSQLiteStoreType
                               configuration:nil
                                         URL:dbURL
                                     options:nil
                                       error:&error]) {
            [NSException raise:@"Open failed" format:@"Reason: %@", [error localizedDescription]];
        }
        context = [[NSManagedObjectContext alloc]init];
        [context setPersistentStoreCoordinator:psc];
        
        [context setUndoManager:nil];
    }
    return self;

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
- (RSSChannel *)fetchRSSFeedWithCompletion:(void (^)(RSSChannel *, NSError *))block
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
    NSString *cachePath =
        [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                             NSUserDomainMask,
                                             YES) objectAtIndex:0];
    
    cachePath = [cachePath stringByAppendingPathComponent:@"nerd.archive"];
    
    // Load the cached channel
    RSSChannel *cachedChannel =
        [NSKeyedUnarchiver unarchiveObjectWithFile:cachePath];
                                 
    // If one hasn't already been cached, create a blank one to fill up
    if (!cachedChannel)
        cachedChannel = [[RSSChannel alloc] init];
    
    RSSChannel *channelCopy = [cachedChannel copy];
    
    [actorConnection setCompletionBlock:^(RSSChannel *obj, NSError * err) {
        // This is the store's callback code
        if (!err) {            
            [channelCopy addItemsFromChannel:obj];
            [NSKeyedArchiver archiveRootObject:channelCopy
                                        toFile:cachePath];
        }
        
        // This is the controller's callback code
        block (channelCopy, err);
    }];
    
    // Let the empty channel parse the returning data from the web service
    [actorConnection setXmlRootObject:channel];
    
    // Begin the connection
    NSLog(@"\t[BNRStore] actorConnection start");
    [actorConnection start];
    
    return cachedChannel;
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


// implement markItemAsRead: to insert a new Link entity into Core Data with the URL of
// the RSSItem’s link.
- (void)markItemAsRead:(RSSItem *)item
{
    // If the item is already in Core data, no need for duplicates
    if ([self hasItemBeenRead:item])
        return;
    
    // Create a new Link object and insert it into the context
    NSManagedObject *obj = [NSEntityDescription
                            insertNewObjectForEntityForName:@"Link"
                            inManagedObjectContext:context];

    // Set the Link's urlString from the RSSItem
    [obj setValue:[item link] forKey:@"urlString"];
    
    // immediately save the changes
    [context save:nil];
}


// implement hasItemBeenRead: to return YES if the RSSItem passed as an argument has its link
// stored in Core Data
- (BOOL)hasItemBeenRead:(RSSItem *)item
{
    // Create a request to fetch all link's with the same urlString as this item link
    NSFetchRequest *req = [[NSFetchRequest alloc] initWithEntityName:@"Link"];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"urlString like %@", [item link]];
    
    [req setPredicate:pred];
    
    // If there is at least one Link, then this item has been read before
    NSArray *entries = [context executeFetchRequest:req error:nil];
    if ([entries count] > 0)
        return YES;
    
    // If Core Data has never seen this link, then it hasn't been read
    return NO;
    
}


@end
