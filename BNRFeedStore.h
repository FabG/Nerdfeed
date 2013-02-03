//
//  BNRFeedStore.h
//  Nerdfeed
//
//  Created by Fabrice Guillaume on 2/2/13.
//  Copyright (c) 2013 Fabrice Guillaume. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RSSChannel;

@interface BNRFeedStore : NSObject

+ (BNRFeedStore *)sharedStore;

@property (nonatomic, strong) NSDate *topSongsCacheDate;

- (void)fetchTopSongs:(int)count
       withCompletion:(void (^) (RSSChannel *obj, NSError *err))block;
                                                 
- (RSSChannel *)fetchRSSFeedWithCompletion:(void (^)(RSSChannel *obj, NSError *err))block;

@end
