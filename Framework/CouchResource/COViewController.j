@import <AppKit/CPArrayController.j>
@import <AppKit/CPViewController.j>
@import <GrowlCappuccino/GrowlCappuccino.j>
@import "COArrayController.j"
@import "COCategories.j"


@implementation COViewController : CPViewController
{
    @outlet              COArrayController arrayController;
    @outlet              CPTableView itemsTable;
    @outlet              CPButton saveModelButton;

    CPObject              modelClass @accessors();
    CPMutableArray        items @accessors();
    TNGrowlCenter         growlCenter @accessors();
    /*CPMutableDictionary   clientsLookup;*/
}

- (id)initWithCibName:(CPString) aCibNameOrNil
      bundle: (CPBundle) aCibBundleOrNil
      modelClass: (CPObject) aModelClass
{
    self = [super initWithCibName:aCibNameOrNil bundle:aCibBundleOrNil];
    if (self)
    {
        modelClass = aModelClass;
        items = [modelClass all];
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
    var item = [self lastSelectedObject];
    if (![item coId])
    {
        [item setCoId:[[item class] couchId:item]];
    }
    var wasSuccessfull = [item save];
    if ([self growlCenter])
    {
        if (wasSuccessfull)
        {
            var message = [CPString stringWithFormat:@"doc: %@ \nwas saved", item.coId];
            [growlCenter pushNotificationWithTitle:@"saved" message:message];
        } else {
            var message = [CPString stringWithFormat:@"doc: %@ \nerror", item.coId];
            [growlCenter pushNotificationWithTitle:@"error" message:message];
        }
    }
    /*if (![clientsLookup valueForKey:[client coId]])
    {
        //[clientsForProjectsPopUp addItemWithTitle:[client name]];
        [clientsLookup setObject:client forKey:[client coId]];
    }*/
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
