@import "COResource.j"
@import <Foundation/CPDictionary.j>

var couchVersions = [[CPDictionary alloc] init];

@implementation COResourceVersioned : COResource
{
    CPString identifier @accessors;
    CPString prevCoRev @accessors;
}

- (BOOL)save
{
    [self setPrevCoRev:[self coRev]];
    var documentSaved = [super save];
    if (documentSaved && [self prevCoRev] != null)
    {
        var path = [[self class] resourcePath] +
                   "/" + identifier +
                   "/" + [self prevCoRev] + "?rev=" + [self coRev];
        var request = [CPURLRequest requestJSONWithURL:path];
        [request setHTTPMethod:@"PUT"];
        [request setHTTPBody:[couchVersions objectForKey:[self prevCoRev]]];

        var response = [CPURLConnection sendSynchronousRequest:request];
        if (response[0] >= 400)
        {
            return NO;
        } else {
            [self setCoRev:[response[1] objectFromJSON].rev];
            [self setCoAttachments: [self loadAttributes]];
            [self addCouchVersion];
            return YES;
        }
    } else {
        return documentSaved;
    }
}

- (void)addCouchVersion
{
    console.log("coRev", [self coRev]);
    if ([self coRev] != null)
    {
        [couchVersions setObject:[CPString JSONFromObject:[self attributes]] forKey:[self coRev]];
    }
}

- (id)loadAttributes
{
    var path = [[self class] resourcePath] + "/" + identifier,
        response = [CPURLConnection sendSynchronousRequest:[CPURLRequest requestJSONWithURL:path]],
        attachments = [response[1] objectFromJSON]._attachments;
    return attachments;
}

- (void)isSelected
{
    if (![couchVersions containsKey:[self coRev]])
    {
        [self addCouchVersion];
    }
}

@end
