@import <Foundation/CPObject.j>
@import <Foundation/CPMutableArray.j>
@import "COCategories.j"


var defaultIdentifierKey = @"_id",
    classAttributeNames  = [CPDictionary dictionary];

@implementation COResource : CPObject
{
    CPString identifier @accessors;
}

// override this method to use a custom identifier for lookups
+ (CPString)identifierKey
{
    return defaultIdentifierKey;
}

// this provides very, very basic pluralization (adding an 's').
// override this method for more complex inflections
+ (CPURL)resourcePath
{
    return [CPURL URLWithString:@"/" + [self underscoreName] + @"s"];
}

+ (CPString)underscoreName
{
    var className = [self className],
        classNameFirst3 = [className substringToIndex:3];
    if (classNameFirst3 == [classNameFirst3 uppercaseString]) // remove namespace
    {
        return [[[self className] substringFromIndex:2] underscoreString];
    } else {
        return [[self className] underscoreString];
    }
}

// you must override this method to generate a couchdbID
/*+ (id)couchId:(id)aItem
{
    return [aItem myProperty];
}*/
+ (id)couchId:(id)aItem
{
    var cType = [[self class] underscoreName];
    return [CPString stringWithFormat:@"%@-%@", cType, [[aItem nameIdentifier] underscoreString]];
}

- (CPString)nameIdentifier
{
    return [self performSelector:CPSelectorFromString([self nameIdentifierString])];
}

- (JSObject)attributes
{
    var json = {},
        classIvars = class_copyIvarList([self class]);
    [classIvars enumerateObjectsUsingBlock:function(ivar) {
            var attr = ivar.name;
            if (ivar.name == 'coId') {
                attr = "_id";
            } else if (ivar.name == 'coRev') {
                attr = "_rev"
            }
            json[attr] = [self performSelector:CPSelectorFromString(ivar.name)];
    }];
    json['type'] = [[self class] underscoreName];
    return json;
}

- (CPArray)attributeNames
{
    if ([classAttributeNames objectForKey:[self className]])
    {
        return [classAttributeNames objectForKey:[self className]];
    }

    var attributeNames = [CPArray array],
        attributes     = class_copyIvarList([self class]);

    for (var i = 0; i < attributes.length; i++)
    {
        [attributeNames addObject:attributes[i].name];
    }

    [classAttributeNames setObject:attributeNames forKey:[self className]];

    return attributeNames;
}

/* overwrite this for labelTransformation*/
- (CPString) transformLabel:(CPString) aLabel
{
    return aLabel;
}

- (void)setAttributes:(JSObject)attributes
{

    for (var attribute in attributes)
    {
        if (attribute == [[self class] identifierKey])
        {
            [self setIdentifier:attributes[attribute].toString()];
        } else {
            var attributeName = [attribute cappifiedString];
            if ([[self attributeNames] containsObject:attributeName])
            {
                var value = attributes[attribute];
                /*
                 * I would much rather retrieve the ivar class than pattern match the
                 * response from Rails, but objective-j does not support this.
                */
                switch (typeof value)
                {
                    case "boolean":
                        if (value)
                        {
                            [self setValue:YES forKey:attributeName];
                        } else {
                            [self setValue:NO forKey:attributeName];
                        }
                        break;
                    case "number":
                        [self setValue:value forKey:attributeName];
                        break;
                    case "string":
                        /*if (value.match(/^\d{4}-\d{2}-\d{2}$/)) {
                            // its a date
                            [self setValue:[CPDate dateWithDateString:value] forKey:attributeName];
                        } else if (value.match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\+\d{2}:\d{2}|Z)$/)) {
                            // its a datetime
                            [self setValue:[CPDate dateWithDateTimeString:value] forKey:attributeName];
                        } else {
                            // its a string*/
                            [self setValue:value forKey:attributeName];
                        //}
                        break;
                    case "object":
                        try {
                            if ([value className] == @"_CPJavaScriptArray") {
                                var valueArray = [[CPArray alloc] initWithArray:value];
                                var label = [self transformLabel:attributeName];
                                var objectContainer = [[COItemsParent alloc] initWithLabel:label];
                                var objectArray = [objectContainer items];
                                [valueArray enumerateObjectsUsingBlock:function(item) {
                                    var subObjectClassName = [CPString stringWithFormat:@"%@%@", [self className], [attributeName capitalizedString]];
                                    var subObjectClass = CPClassFromString(subObjectClassName);
                                    [objectArray addObject:[[subObjectClass alloc] initWithJSObject:item]];
                                }];
                                [self setValue:objectContainer forKey:attributeName];
                            }
                        }
                        catch (err)
                        {
                            if (attributeName == @"coAttachments") {
                                [self setValue:value forKey:attributeName];
                            }
                        }
                        break;
                    default:
                        console.log("### no match found", attributeName);
                }
            }
        }
    }
}

+ (id)new
{
    return [self new:nil];
}

+ (id)new:(JSObject)attributes
{
    var resource = [[self alloc] initFromCouch];

    if (!attributes)
        attributes = {};

    [resource setAttributes:attributes];
    return resource;
}

+ (id)create:(JSObject)attributes
{
    var resource = [self new:attributes];
    if ([resource save]) {
        return resource;
    } else {
        return nil;
    }
}

- (BOOL)save
{
    var request = [self resourceWillSave];

    if (!request) {
        return NO;
    }

    var response = [CPURLConnection sendSynchronousRequest:request];

    if (response[0] >= 400) {
        [self resourceDidNotSave:response[1]];
        return NO;
    } else {
        [self resourceDidSave:response[1]];
        [self setCoRev:[response[1] objectFromJSON].rev]
        return YES;
    }
}

- (BOOL)destroy
{
    var request = [self resourceWillDestroy];

    if (!request) {
        return NO;
    }

    var response = [CPURLConnection sendSynchronousRequest:request];

    if (response[0] == 200) {
        [self resourceDidDestroy];
        return YES;
    } else {
        return NO;
    }
}

+ (CPArray)all
{
    var request = [self collectionWillLoad];

    if (!request) {
        return NO;
    }

    var response = [CPURLConnection sendSynchronousRequest:request];

    if (response[0] >= 400) {
        return nil;
    } else {
        return [self collectionDidLoad:response[1]];
    }
}

+ (CPArray)allWithParams:(JSObject)params
{
    var request = [self collectionWillLoad:params];

    var response = [CPURLConnection sendSynchronousRequest:request];

    if (response[0] >= 400) {
        return nil;
    } else {
        return [self collectionDidLoad:response[1]];
    }
}

+ (id)find:(CPString)identifier
{
    var request = [self resourceWillLoad:identifier];

    if (!request) {
        return NO;
    }

    var response = [CPURLConnection sendSynchronousRequest:request];

    if (response[0] >= 400) {
        return nil;
    } else {
        return [self resourceDidLoad:response[1]];
    }
}

+ (id)findWithParams:(JSObject)params
{
    var collection = [self allWithParams:params];

    if ([collection count] > 0) {
        return [collection objectAtIndex:0];
    } else {
        return nil;
    }
}

// All the following methods post notifications using their class name
// You can observe these notifications and take further action if desired
+ (CPURLRequest)resourceWillLoad:(CPString)identifier
{
    var path             = [self resourcePath] + "/" + identifier,
        notificationName = [self className] + "ResourceWillLoad";

    if (!path) {
        return nil;
    }

    var request = [CPURLRequest requestJSONWithURL:path];
    [request setHTTPMethod:@"GET"];

    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
    return request;
}

+ (id)resourceDidLoad:(CPString)aResponse
{
    var response         = [aResponse toJSON],
        attributes       = response[[self underscoreName]],
        notificationName = [self className] + "ResourceDidLoad",
        resource         = [self new];

    [resource setAttributes:attributes];
    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:resource];
    return resource;
}

+ (CPURLRequest)collectionWillLoad
{
    return [self collectionWillLoad:nil];
}

// can handle a JSObject or a CPDictionary
+ (CPURLRequest)collectionWillLoad:(id)params
{
    var path             = [self resourcePath],
        notificationName = [self className] + "CollectionWillLoad";

    if (params) {
        if (params.isa && [params isKindOfClass:CPDictionary]) {
            path += ("?" + [CPString paramaterStringFromCPDictionary:params]);
        } else {
            path += ("?" + [CPString paramaterStringFromJSON:params]);
        }
    }

    if (!path) {
        return nil;
    }

    var request = [CPURLRequest requestJSONWithURL:path];
    [request setHTTPMethod:@"GET"];

    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self];

    return request;
}

+ (CPArray)collectionDidLoad:(CPString)aResponse
{
    var resourceArray    = [CPArray array],
        notificationName = [self className] + "CollectionDidLoad";

    if ([[aResponse stringByTrimmingWhitespace] length] > 0) {
        var collection = [aResponse toJSON];

        for (var i = 0; i < collection.length; i++) {
            var resource   = collection[i];
            var attributes = resource;
            [resourceArray addObject:[self new:attributes]];
        }
    }

    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:resourceArray];
    return resourceArray;
}

- (CPURLRequest)resourceWillSave
{
    var abstractNotificationName = [self className] + "ResourceWillSave";
    var attributes = [self attributes];

    if (identifier) {
        var path             = [[self class] resourcePath] + "/" + identifier,
            notificationName = [self className] + "ResourceWillUpdate";
    } else {
        [self setCoId:[[self class] couchId:self]];
        //[self setType:[[self class] underscoreName]];
        delete attributes._rev; // remove _rev from JSON, couchdb doesn't accept "_rev":null
        var path             = [[self class] resourcePath],
            notificationName = [self className] + "ResourceWillCreate";
    }
    if (!path) {
        return nil;
    }

    if (attributes._rev == null) {
        delete attributes._rev; // remove _rev from JSON, couchdb doesn't accept "_rev":null
    }

    var request = [CPURLRequest requestJSONWithURL:path];

    [request setHTTPMethod:identifier ? @"PUT" : @"POST"];
    [request setHTTPBody:[CPString JSONFromObject:attributes]];

    //[request setHTTPBody:JSON.stringify(attributes)];

    if (!attributes._rev) [self setIdentifier:[[self class] couchId:self]];

    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
    [[CPNotificationCenter defaultCenter] postNotificationName:abstractNotificationName object:self];
    return request;
}

- (void)resourceDidSave:(CPString)aResponse
{
    if ([aResponse length] > 1)
    {
        var response    = [aResponse toJSON],
            attributes  = response[[[self class] underscoreName]];
    }
    var abstractNotificationName = [self className] + "ResourceDidSave";

    if (identifier) {
        var notificationName = [self className] + "ResourceDidUpdate";
    } else {
        var notificationName = [self className] + "ResourceDidCreate";
    }
    [self setAttributes:attributes];
    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
    [[CPNotificationCenter defaultCenter] postNotificationName:abstractNotificationName object:self];
}

- (void)resourceDidNotSave:(CPString)aResponse
{
    //CPLog.debug(@"not saveed response %@", [aResponse objectFromJSON]);
    var abstractNotificationName = [self className] + "ResourceDidNotSave";

    // TODO - do something with errors
    if (identifier) {
        var notificationName = [self className] + "ResourceDidNotUpdate";
    } else {
        var notificationName = [self className] + "ResourceDidNotCreate";
    }

    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
    [[CPNotificationCenter defaultCenter] postNotificationName:abstractNotificationName object:self];
}

- (CPURLRequest)resourceWillDestroy
{
    var path             = [[self class] resourcePath] + "/" + identifier + "?rev=" + [self coRev],
        notificationName = [self className] + "ResourceWillDestroy";

    if (!path) {
        return nil;
    }

    var request = [CPURLRequest requestJSONWithURL:path];
    [request setHTTPMethod:@"DELETE"];

    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
    return request;
}

-(void)resourceDidDestroy
{
    var notificationName = [self className] + "ResourceDidDestroy";
    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
}

// overwrite this
- (CPString)nameIdentifierString
{
    return @"name";
}

// hook overwrite
- (void) isSelected
{
}

- (id)initFromCouch
{
    self = [super init];
    return self;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        //[self setType:[[self class] underscoreName]];
        var selector = [CPString stringWithFormat:@"set%@:", [[self nameIdentifierString] capitalizedString]],
            newName  = [CPString stringWithFormat:@"new %@", [[self class] underscoreName]];
        [self performSelector:CPSelectorFromString(selector) withObject:newName];

    }
    return self;
}

@end

