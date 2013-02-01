//
//  ListViewController.h
//  Nerdfeed
//
//  Created by Fabrice Guillaume on 1/30/13.
//  Copyright (c) 2013 Fabrice Guillaume. All rights reserved.
//

#import <Foundation/Foundation.h>

// a forward declaration; we'll import the header in the .m
@class RSSChannel;
@class WebViewController;

@interface ListViewController : UITableViewController <NSXMLParserDelegate>
{
    NSURLConnection *connection;
    NSMutableData *xmlData;
    
    RSSChannel *channel;
}

@property (nonatomic,strong) WebViewController *webViewController;

- (void)fetchEntries;

@end
