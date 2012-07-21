@import <AppKit/CPArrayController.j>
@import <AppKit/CPViewController.j>
@import <CouchResource/COArrayController.j>
@import <CouchResource/COCategories.j>


@implementation COViewController : CPViewController
{
    IBOutlet              COArrayController arrayController;
    IBOutlet              CPTableView itemsTable;
    IBOutlet              CPButton saveModelButton;

    CPObject              modelClass @accessors();
    CPMutableArray        items @accessors();
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
        var items = [modelClass all];
        [items class];
    }
    return self;
}

- (id)lastSelectedObject
{
    var selectedObject = [[arrayController selectedObjects] lastObject];
    return selectedObject;
}

- (void)saveModel:(id)sender
{
    var item = [self lastSelectedObject];
    if (![item coId])
    {
        [item setCoId:[[item class] couchId:item]];
    }
    [item save];
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
