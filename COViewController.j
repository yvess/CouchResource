@import <AppKit/CPViewController.j>
@import <AppKit/CPTableView.j>
@import "COArrayController.j"
@import "COCategories.j"

var COGrowlCenter = nil;

@implementation COViewController : CPViewController
{
    @outlet              COArrayController arrayController;
    @outlet              CPTableView itemsTable;
    @outlet              CPButton saveModelButton;

    CPObject              modelClass @accessors();
    CPMutableArray        items @accessors();
}

+ (id)couchId
{
    var cType = [[self class] underscoreName];
    return [CPString stringWithFormat:@"%@-%@", cType, [self nextUUID]];
}

+ (CPArray)allItemsFor:(CPObject) aModelClass
{
    return [aModelClass all];
}

- (id)initWithCibName:(CPString) aCibNameOrNil
      bundle: (CPBundle) aCibBundleOrNil
      modelClass: (CPObject) aModelClass
      growlCenter: (TNGrowlCenter) aGrowlCenter
{
    self = [super initWithCibName:aCibNameOrNil bundle:aCibBundleOrNil];
    if (self)
    {
        modelClass = aModelClass;
        items = [[self class] allItemsFor:modelClass]
    }
    if (!COGrowlCenter) {
        COGrowlCenter = aGrowlCenter;
    }
    return self;
}

- (void)reloadItems
{
    [self setItems:[modelClass all]];
}

- (void)setSelectionIndex:(int)index
{
    [arrayController setSelectionIndex:index];
}

- (id)lastSelectedObject
{
    var selectedObject = [[arrayController selectedObjects] lastObject];
    return selectedObject;
}

- (int)selectionIndex
{
    return [arrayController selectionIndex];
}

- (void)saveModel:(id)sender
{
    [[[sender window] firstResponder] resignFirstResponder];
    var item = [self lastSelectedObject];
    if (![item coId])
    {
        [item setCoId:[[item class] couchId]];
    }
    var wasSuccessfull = [item save];
    if (COGrowlCenter)
    {
        if (wasSuccessfull)
        {
            var message = [CPString stringWithFormat:@"doc: %@ \nwas saved", [item nameIdentifier]];
            [COGrowlCenter pushNotificationWithTitle:@"saved" message:message];
        } else {
            var message = [CPString stringWithFormat:@"doc: %@ \nerror", item.coId];
            [COGrowlCenter pushNotificationWithTitle:@"error" message:message];
        }
    }
}

- (CPMutableDictionary)createLookup
{
    var itemLookup = [[CPMutableDictionary alloc] init];
    [items enumerateObjectsUsingBlock:function(item) {
        [itemLookup setObject:item forKey:[item coId]];
    }];
    return itemLookup;
}

- (void)viewDidLoad
{
    [saveModelButton setTarget:self];
    [saveModelButton setAction:@selector(saveModel:)];
}
@end
