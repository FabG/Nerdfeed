//
//  RSSChannel.h
//  Nerdfeed
//
//  Created by Fabrice Guillaume on 1/31/13.
//  Copyright (c) 2013 Fabrice Guillaume. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSSChannel : NSObject <NSXMLParserDelegate>
{
    NSMutableString *currentString;     // local pointer
}

@property (nonatomic, weak) id parentParserDelegate;

@property (nonatomic,strong) NSString *title;
@property (nonatomic,strong) NSString *infoString;
@property (nonatomic,readonly,strong) NSMutableArray *items;

@end
