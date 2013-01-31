//
//  ListViewController.h
//  Nerdfeed
//
//  Created by Fabrice Guillaume on 1/30/13.
//  Copyright (c) 2013 Fabrice Guillaume. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ListViewController : UITableViewController
{
    NSURLConnection *connection;
    NSMutableData *xmlData;
}
- (void)fetchEntries;

@end
