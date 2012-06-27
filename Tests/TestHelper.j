// import all the necessary stuff to run tests
@import <Foundation/CPObject.j>
@import <OJMoq/OJMoq.j>
@import "../Framework/CouchResource/DMBasae.j"

@implementation Observer : CPObject
{
    CPArray _postedNotifications;
}

- (id)init
{
    if (self = [super init])
    {
        _postedNotifications   = [CPArray array];
    }
    return self;
}

- (void)startObserving:(CPString)aNotificationName
{
    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notificationPosted:)
                                                 name:aNotificationName
                                               object:nil];
}

- (void)notificationPosted:(id)sender
{
    [_postedNotifications addObject:[sender name]];
}

- (BOOL)didObserve:(CPString)aNotificationName
{
    return [_postedNotifications containsObject:aNotificationName];
}

@end

// define some classes which inherit from CR to use in testing

@implementation User : CouchResource
{
    CPString  email       @accessors;
    CPString  password    @accessors;
    int       age         @accessors;
    BOOL      isAlive     @accessors;
}

- (JSObject)attributes
{
    return {'email':email,'password':password, 'age':age};
}

@end

@implementation UserSession : CouchResource
{
    CPString userName  @accessors;
    CPDate   startDate @accessors;
}

- (JSObject)attributes
{
    return {'user_name':userName,'start_date':[startDate toDateString]};
}


+ (CPString)identifierKey
{
    return @"token";
}

@end
