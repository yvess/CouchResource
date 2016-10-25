
@implementation COItemsParent : CPObject
{
  CPString        label @accessors();
  CPMutableArray  items @accessors(readonly);
}

- (id)initWithLabel:(CPString)aLabel
{
    self = [super init];
    if (self)
    {
      items = [[CPMutableArray alloc] init];
      [self setLabel:aLabel];
    }
    return self;
}

- (CPString)objectValueForOutlineColumn:(CPString)aTableColumn
{
  return [self label];
}
@end
