//
//  BNRConnection.h
//  Nerdfeed
//
//  Created by Fabrice Guillaume on 2/2/13.
//  Copyright (c) 2013 Fabrice Guillaume. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BNRConnection : NSObject <NSURLConnectionDataDelegate, NSURLConnectionDataDelegate>
{
    NSURLConnection *internalConnection;
    NSMutableData *dataContainer;
}

- (id)initWithRequest:(NSURLRequest *)req;

@property (nonatomic, copy) NSURLRequest *request;
@property (nonatomic, copy) void (^completionBlock) (id obj, NSError *err);
@property (nonatomic, strong) id <NSXMLParserDelegate> xmlRootObject;

- (void)start;

@end
