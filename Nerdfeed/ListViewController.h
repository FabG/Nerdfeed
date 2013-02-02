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

// A new protocol to send to message to WebViewController if a row in the table is tapped
// and to the ChannelViewController if the Info button is tapped
@protocol  ListViewControllerDelegate

// Classes that conform to this protocol must implement this method
// To note we pass an id for the selected row
// - when user clicks on a row (RSSItem) -> WebViewController
// - when user taps info button -> ChanelViewController
- (void)listViewController:(ListViewController *)lvc handleObject:(id)object;

@end
