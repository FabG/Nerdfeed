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

- (void)parser:(NSXMLParser *)parser
    didStartElement:(NSString *)elementName
    namespaceURI:(NSString *)namespaceURI
    qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict
{
    //NSLog(@"\t\t%@ found a %@ element", self, elementName);
    
    if ([elementName isEqual:@"title"]) {
        currentString = [[NSMutableString alloc] init];
        [self setTitle:currentString];
    }
    else if ([elementName isEqual:@"link"]) {
        currentString = [[NSMutableString alloc] init];
        [self setLink:currentString];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)str
{
    [currentString appendString:str];
}

- (void)parser:(NSXMLParser *)parser
    didEndElement:(NSString *)elementName
    namespaceURI:(NSString *)namespaceURI
    qualifiedName:(NSString *)qName
{
    currentString = nil;
    
    
    if ([elementName isEqual:@"item"]
        ||[elementName isEqual:@"entry"]) {
        [parser setDelegate:parentParserDelegate];
    }
}

// JSON
- (void)readFromJSONDictionary:(NSDictionary *)d
{
    [self setTitle:[[d objectForKey:@"title"] objectForKey:@"label"]];
    
    // Inside each entry is an array of links, each has an attribute object
    NSArray *links = [d objectForKey:@"link"];
    if ([links count] > 1) {
        NSDictionary *sampleDict = [[links objectAtIndex:1] objectForKey:@"attributes"];
        
        // The href of an attribute object is the URL for the sample audio file
        [self setLink:[sampleDict objectForKey:@"href"]];
    }
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:title forKey:@"title"];
    [aCoder encodeObject:link forKey:@"link"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self setTitle:[aDecoder decodeObjectForKey:@"title"]];
        [self setLink:[aDecoder decodeObjectForKey:@"link"]];
    }
    return self;
}

@end
