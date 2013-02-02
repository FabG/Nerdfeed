//
//  RSSChannel.m
//  Nerdfeed
//
//  Created by Fabrice Guillaume on 1/31/13.
//  Copyright (c) 2013 Fabrice Guillaume. All rights reserved.
//

#import "RSSChannel.h"
#import "RSSItem.h"

@implementation RSSChannel

@synthesize items, title, infoString, parentParserDelegate;

- (id)init
{
    self = [super init];
    
    if (self) {
        // Create the container for the RSSItems this channel has;
        items = [[NSMutableArray alloc]init];
    }
    
    return self;
}

// The channel is interested into the "title" and "description" metadata elements
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
        namespaceURI:(NSString *)namespaceURI
        qualifiedName:(NSString *)qName
        attributes:(NSDictionary *)attributeDict
{
    //NSLog(@"\t[RSSC] %@found a %@ element", self, elementName);
    
    if ([elementName isEqual:@"title"]) {
        currentString = [[NSMutableString alloc]init];
        [self setTitle:currentString];
        //NSLog(@"\t[RSSC] %@found a %@ element", self, elementName);
    }
    else if ([elementName isEqual:@"description"]) {
        currentString = [[NSMutableString alloc]init];
        [self setInfoString:currentString];
        //NSLog(@"\t[RSSC] %@found a %@ element", self, elementName);
    }
    else if ([elementName isEqual:@"item"]) {
        // When we find an item, create an instance of RSSItem
        RSSItem *entry = [[RSSItem alloc]init];
        
        // Set up its parent as ourselves so we can regain control of the parser
        [entry setParentParserDelegate:self];
        NSLog(@"\t[RSSC] %@found a %@ element", self, elementName);

        // Turn the parser to the RSSItem
        [parser setDelegate:entry];
        NSLog(@"\t  [RSSC] Item is now parser's delegate");
        
        // Add the item to our array and release our hold on it
        [items addObject:entry];
    }
}

// implement foundCharacters method
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [currentString appendString:string];
}

// When the parser finds the end of the channel element, the channel object will return control
// of the parser to the ListViewController
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
    namespaceURI:(NSString *)namespaceURI
    qualifiedName:(NSString *)qName
{
    // If we were in an element that we were collecting the string for, this appropriately
    // releases our hold on it and the permanent ivar keeps ownership of it.
    // If we weren't parsing such and element, currentString is nil already
    currentString = nil;
    
    // If the element that ended was the channel, give up control to who gave us control
    // in the first place
    if ([elementName isEqual:@"channel"])
        [parser setDelegate:parentParserDelegate];
}

@end
