@import <Foundation/CPDate.j>
@import <Foundation/CPString.j>
@import <Foundation/CPURLConnection.j>
@import <Foundation/CPURLRequest.j>

@implementation CPDate (COSupport)

+ (CPDate)dateWithDateString:(CPString)aDate
{
    return [[self alloc] initWithString:aDate + " 12:00:00 +0000"];
}

+ (CPDate)dateWithDateTimeString:(CPString)aDateTime
{
    var format = /^(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})(\+\d{2}:\d{2}|Z)?$/,
        d      = aDateTime.match(new RegExp(format));

    if (d[3] === 'Z')
        d[3] = '+00:00';

    var string = d[1] + " " + d[2] + " " + d[3].replace(':', '');
    return [[self alloc] initWithString:string];
}

- (int)year
{
    return self.getFullYear();
}

- (int)month
{
    return self.getMonth() + 1;
}

- (int)day
{
    return self.getDate();
}

- (CPString)toDateString
{
    return [CPString stringWithFormat:@"%04d-%02d-%02d", [self year], [self month], [self day]];
}
@end


@implementation CPString (COSupport)

+ (CPString)paramaterStringFromJSON:(JSObject)params
{
    paramsArray = [CPArray array];

    for (var param in params)
    {
        [paramsArray addObject:(escape(param) + "=" + escape(params[param]))];
    }

    return paramsArray.join("&");
}

+ (CPString)paramaterStringFromCPDictionary:(CPDictionary)params
{
    var paramsArray = [CPArray array],
        keys        = [params allKeys];

    for (var i = 0; i < [params count]; ++i)
    {
        [paramsArray addObject:(escape(keys[i]) + "=" + escape([params valueForKey:keys[i]]))];
    }

    return paramsArray.join("&");
}

- (CPString)transformToSetter
{
    var aString = [CPString stringWithFormat:@"%@%@",
        [[self substringToIndex:1] uppercaseString],
         [self substringFromIndex:1]];
    return [CPString stringWithFormat:@"set%@", aString];
}


- (CPString)underscoreString
{
    var str = self,
        str_path = str.split(' '),
        upCase = new RegExp('([ABCDEFGHIJKLMNOPQRSTUVWXYZ])','g'),
        fb = new RegExp('^_');
    for (var i = 0;i < str_path.length;i++)
    {
      str_path[i] = str_path[i].replace(upCase,'_$1').replace(fb,'');
    }
    str = str_path.join('_').toLowerCase();

    return str;
}

/*
 * Cappuccino expects strings to be camelized with a lowercased first letter.
 * eg - userSession, movieTitle, createdAt, etc.
 * Always use this format when declaring ivars.
*/
- (CPString)cappifiedString
{
    var string = self.charAt(0).toLowerCase() + self.substring(1),
        array  = string.split('_');
    for (var x = 1; x < array.length; x++) // skip first word
        array[x] = array[x].charAt(0).toUpperCase() +array[x].substring(1);
    string = array.join('');

    return string;
}

- (JSObject)toJSON
{
    var str = self;
    try {
        var obj = JSON.parse(str);
    }
    catch (anException) {
        CPLog.warn(@"Could not convert to JSON: " + str);
    }

    if (obj)
    {
        return obj;
    }
}
@end


@implementation CPURLConnection (COSupport)

// Works just like built-in method, but returns CPArray instead of CPData.
// First value in array is HTTP status code, second is data string.
+ (CPArray)sendSynchronousRequest:(CPURLRequest)aRequest
{
    try {
        var request = new CFHTTPRequest();

        request.open([aRequest HTTPMethod], [[aRequest URL] absoluteString], NO);

        var fields = [aRequest allHTTPHeaderFields],
            key = nil,
            keys = [fields keyEnumerator];

        while (key = [keys nextObject])
            request.setRequestHeader(key, [fields objectForKey:key]);

        request.send([aRequest HTTPBody]);

        return [CPArray arrayWithObjects:request.status(), request.responseText()];
     }
     catch (anException) {}

     return nil;
}
@end


@implementation CPURLRequest (COSupport)

+ (id)requestJSONWithURL:(CPURL)aURL
{
    var request = [self requestWithURL:aURL];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    return request;
}
@end
