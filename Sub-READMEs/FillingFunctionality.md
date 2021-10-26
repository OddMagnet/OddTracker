# Filling Functionality

## Adding and deleting

So far the app has functionality to edit items and projects and also delete projects, but not adding them in the first place. 

To add new projects the `.toolbar()` modifier is used to add a `Button` view, which creates a new, open project and saves it right away. This button only shows when viewing open projects.

The functionality to add items is attached directly to each project, as a static row containing a buttonw view, after the `ForEach` view in `ProjectsView` that lists all the items in a project. It creates a new items and saves it right away.

To delete items the `.onDelete()` modifier is used, with a closure that accepts the offsets of items that will be deleted, goes over the offsets and deletes every item, then saves the changes.

SwiftUI also offers a dedicated `.remove(atOffsets:)` modier, but since it is necessary to know both which item index and which projects index to delete from the Core Data context, the above modifier won't work. 

The `.onDelete()` approach works for two reasons:

- it gets passed an `IndexSet` (a special collection type that is sorted and only contains unique integers >=0), so there is no need to worry about index order
- deleting a Core Data object doesn't remove it until `save()` is called on the data controller, which means indexes won't change as each item is deleted
