@import "COCategories.j"

@implementation COSubItem : CPObject
{
}

- (id)initWithJSObject:(id)anObject
{
    self = [super init];
    if (self)
    {
        var classIvars = class_copyIvarList([self class]);
        [classIvars enumerateObjectsUsingBlock:function(ivar) {
            var setter = [CPString stringWithFormat:@"%@:", [ivar.name transformToSetter]],
                jsonName = [ivar.name underscoreString];
            [self performSelector:CPSelectorFromString(setter) withObject:anObject[jsonName]];
        }];
    }
    return self;
}

- (JSObject)JSONFromObject
{
    var json = {},
        classIvars = class_copyIvarList([self class]);
    [classIvars enumerateObjectsUsingBlock:function(ivar) {
        var jsonName = [ivar.name underscoreString],
            ivarName = ivar.name;
        json[jsonName] = [self performSelector:CPSelectorFromString(ivarName)];
    }];
    return json;
}
@end
