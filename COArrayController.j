@import <AppKit/CPArrayController.j>
@import <Foundation/CPNotificationCenter.j>

@implementation COArrayController : CPArrayController

- (void)remove:(id)sender
{
    var objectToRemove = [[self selectedObjects] objectAtIndex:0];
    [[CPNotificationCenter defaultCenter] postNotificationName:@"DMRemoveTableRow" object:objectToRemove];
    [self removeObject:objectToRemove];
    [objectToRemove destroy];
}

- (void)insert:(id)sender
{
    [super insert:sender];
    [[CPNotificationCenter defaultCenter] postNotificationName:@"DMAddTableRow" object:[self selectedObjects]];
}
@end
