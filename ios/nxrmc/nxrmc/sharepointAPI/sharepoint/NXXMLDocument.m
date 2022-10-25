//
//  NXXMLDocument.m
//  RecordWebRequest
//
//  Created by ShiTeng on 15/5/27.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//

#import "NXXMLDocument.h"
#pragma mark NXXMLElement =================================
@interface NXXMLElement()

@end

@implementation NXXMLElement
#pragma mark NXXMLElement Operation
-(NSArray*) childrenNamed:(NSString*) nodeName
{
    NSMutableArray* array = [[NSMutableArray alloc] init];
    for (NXXMLElement* node in self.children) {
        if ([node.name isEqualToString:nodeName]) {
            [array addObject:node];
        }
    }
    
    return [array copy];
}

-(NXXMLElement*) childNamed:(NSString*) nodeName
{
    for (NXXMLElement* node in self.children) {
        if ([node.name isEqualToString:nodeName]) {
            return node;
        }
    }
    return nil;
}

- (NSString *)attributeNamed:(NSString *)attributeName
{
    return [self.attributes objectForKey:attributeName];
}

- (NXXMLElement *)descendantWithPath:(NSString *)path
{
    NXXMLElement *descendant = self;
    for (NSString *childName in [path componentsSeparatedByString:@"."])
        descendant = [descendant childNamed:childName];
    return descendant;
}

- (NSString *)valueWithPath:(NSString *)path
{
    NSArray *components = [path componentsSeparatedByString:@"@"];
    NXXMLElement *descendant = [self descendantWithPath:[components objectAtIndex:0]];
    return [components count] > 1 ? [descendant attributeNamed:[components objectAtIndex:1]] : descendant.value;
}

#pragma mark NSXMLParserDelegate
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    
    NXXMLElement* child = [[NXXMLElement alloc] init];
    child.name = elementName;
    child.attributes = attributeDict;
    child.parent = self;
    
    if (!_children) {
        _children = [NSMutableArray arrayWithObject:child];
    }else
    {
        [_children addObject:child];
    }
    
    // recursive to child to add child
    parser.delegate = child;
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (!string) {
        return;
    }
    
    if (!_value) {
        _value = [NSMutableString stringWithString:string];
    }else{
        [_value appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    // recursion end(this node is end), back to parent
    parser.delegate = self.parent;
}

#pragma mark Description
-(NSString*) description
{
    return [self descriptionWithIndent:@"" truncatedValues:YES];
}

-(NSString*) descriptionWithIndent:(NSString*) indent truncatedValues:(BOOL) truncated
{
    NSMutableString *s = [NSMutableString string];
    [s appendFormat:@"%@<%@", indent, _name];
    
    for (NSString *attribute in _attributes)
        [s appendFormat:@" %@=\"%@\"", attribute, [_attributes objectForKey:attribute]];
    
    NSString *valueOrTrimmed = [_value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (truncated && valueOrTrimmed.length > 25)
        valueOrTrimmed = [NSString stringWithFormat:@"%@…", [valueOrTrimmed substringToIndex:25]];
    
    if (_children.count) {
        [s appendString:@">\n"];
        
        NSString *childIndent = [indent stringByAppendingString:@"  "];
        
        if (valueOrTrimmed.length)
            [s appendFormat:@"%@%@\n", childIndent, valueOrTrimmed];
        
        for (NXXMLElement *child in _children)
            [s appendFormat:@"%@\n", [child descriptionWithIndent:childIndent truncatedValues:truncated]];
        
        [s appendFormat:@"%@</%@>", indent, _name];
    }
    else if (valueOrTrimmed.length) {
        [s appendFormat:@">%@</%@>", valueOrTrimmed, _name];
    }
    else [s appendString:@"/>"];
    
    return s;
}
@end


#pragma mark NXXMLDocument =================================
@interface NXXMLDocument()
@property(nonatomic, strong) NSXMLParser* xmlParser;
@property(nonatomic, strong) NSError* error;
@end


@implementation NXXMLDocument

#pragma mark INIT and INSTANCE
+(instancetype) documentWithData:(NSData*) data error:(NSError**)outError
{
    return [[NXXMLDocument alloc] initWithData:data error:outError];
}

-(instancetype) initWithData:(NSData*) data error:(NSError**) outError
{
    if (self = [super init]) {
        _xmlParser = [[NSXMLParser alloc] initWithData:data];
        _xmlParser.delegate = self;
        _xmlParser.shouldProcessNamespaces = YES;
        _xmlParser.shouldReportNamespacePrefixes = YES;
        _xmlParser.shouldResolveExternalEntities = NO;
        
        [_xmlParser parse];
        
        if (self.error) {
            if (outError) {
                *outError = self.error;
            }
            
            return  nil;
        }else if(outError)
        {
            *outError = nil;
        }
    }
    return self;
}

#pragma mark NSXMLParserDelegate
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
 
    _root = [[NXXMLElement alloc] init];
    _root.name = elementName;
    _root.attributes = attributeDict;
    
    _xmlParser.delegate = _root;
    
}

#pragma mark Description
-(NSString*) description
{
    return [self.root description];
}


@end
