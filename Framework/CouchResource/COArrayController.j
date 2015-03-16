@import <AppKit/CPArrayController.j>
@import <Foundation/CPNotificationCenter.j>

@implementation COArrayController : CPArrayController

- (void)remove:(id)sender
{
    [[CPNotificationCenter defaultCenter] postNotificationName:@"DMRemoveTableRow" object:[self selectedObjects]];
    [self removeObjects:[[self arrangedObjects] objectsAtIndexes:[self selectionIndexes]]];
}

- (void)insert:(id)sender
{
    [super insert:sender];
    [[CPNotificationCenter defaultCenter] postNotificationName:@"DMAddTableRow" object:[self selectedObjects]];
}
@end
