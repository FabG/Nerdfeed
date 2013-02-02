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

- (void)fetchRSSFeedWithCompletion:(void (^)(RSSChannel *obj, NSError *err))block;

@end
