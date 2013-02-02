//
//  ChannelViewController.h
//  Nerdfeed
//
//  Created by Fabrice Guillaume on 2/1/13.
//  Copyright (c) 2013 Fabrice Guillaume. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ListViewController.h"

@class RSSChannel;
@interface ChannelViewController :
UITableViewController <ListViewControllerDelegate, UISplitViewControllerDelegate>
{
    RSSChannel *channel;
}
@end
