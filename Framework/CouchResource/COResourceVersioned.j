@import "COResource.j"
@import <Foundation/CPDictionary.j>

@implementation COResourceVersioned : COResource
{
    CPString identifier @accessors;
    CPString prevRev @accessors;
    CPDictionary couchVersions @accessors;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        couchVersions = [[CPDictionary alloc] init];
    }
    return self;
}

// - (id)initFromCouch
// {
//     console.log("initFromCouch");
//     self = [self init];
//     if (self)
//     {
//         couchVersions = [[CPDictionary alloc] init];
//         [self addCouchVersion];
//         console.log(couchVersions);
//     }
//     return self;
// }

- (BOOL)save
{
    [self setPrevRev:[self coRev]];
    var documentSaved = [super save];
    if (documentSaved && [self prevRev] != null)
    {
        var path = [[self class] resourcePath] +
                   "/" + identifier +
                   "/" + [self prevRev] + "?rev=" + [self coRev];
        var request = [CPURLRequest requestJSONWithURL:path];
        [request setHTTPMethod:@"PUT"];
        var body = [couchVersions objectForKey:[self prevRev]];
        [request setHTTPBody:body];

        var response = [CPURLConnection sendSynchronousRequestCouch:request];
        if (response[0] >= 400)
        {
            return NO;
        } else {
            [self setCoRev:[response[1] objectFromJSON].rev];
            [self setCoAttachments: [self loadAttachments]];
            [self addCouchVersion];
            return YES;
        }
    } else {
        return documentSaved;
    }
}

- (void)addCouchVersion
{
    if ([self coRev] != null)
    {
        [couchVersions setObject:[CPString JSONFromObject:[self attributes]] forKey:[self coRev]];
    }
}

- (id)loadAttachments
{
    var path = [[self class] resourcePath] + "/" + identifier,
        response = [CPURLConnection sendSynchronousRequestCouch:[CPURLRequest requestJSONWithURL:path]],
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
