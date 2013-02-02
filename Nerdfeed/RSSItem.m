//
//  RSSItem.m
//  Nerdfeed
//
//  Created by Fabrice Guillaume on 1/31/13.
//  Copyright (c) 2013 Fabrice Guillaume. All rights reserved.
//

#import "RSSItem.h"

@implementation RSSItem

@synthesize title, link, parentParserDelegate;

// The RSSItem is interested into the "title" and "link" metadata elements
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
    namespaceURI:(NSString *)namespaceURI
    qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict
{
    
    //NSLog(@"\t\t[RSSI] %@found a %@ element", self, elementName);
    
    if ([elementName isEqual:@"title"]) {
        currentString = [[NSMutableString alloc]init];
        [self setTitle:currentString];
        NSLog(@"\t\t[RSSI] %@found a %@ element", self, elementName);
    }
    else if ([elementName isEqual:@"link"]) {
        currentString = [[NSMutableString alloc]init];
        [self setLink:currentString];
        NSLog(@"\t\t[RSSI] %@found a %@ element", self, elementName);
    }
}

// implement foundCharacters method
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [currentString appendString:string];
    //NSLog(@"\t\t  [RSSI] foundCharacters: %@", string);

}

// When the parser finds the end of the item element, the channel object will return control
// of the parser to the RSSChannel
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
    namespaceURI:(NSString *)namespaceURI
    qualifiedName:(NSString *)qName
{
    currentString = nil;
    
    // If the element that ended was the item, give up control to who gave us control
    // in the first place
    if ([elementName isEqual:@"item"])
        [parser setDelegate:parentParserDelegate];
}

@end
