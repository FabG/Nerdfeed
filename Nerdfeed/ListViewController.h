//
//  ListViewController.h
//  Nerdfeed
//
//  Created by Fabrice Guillaume on 1/30/13.
//  Copyright (c) 2013 Fabrice Guillaume. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RSSChannel;
@class WebViewController;

@interface ListViewController : UITableViewController
{
    RSSChannel *channel;
}

@property (nonatomic, strong) WebViewController *webViewController;
- (void)fetchEntries;

@end

// A new protocol named ListViewControllerDelegate
@protocol ListViewControllerDelegate

// Classes that conform to this protocol must implement this method:
- (void)listViewController:(ListViewController *)lvc handleObject:(id)object;
@end