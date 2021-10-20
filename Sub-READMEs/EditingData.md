# Editing Data

## Editing Items

Displaying projects and items alone is rather useless without a way to add and edit them, so next is the `EditItemView`

This view uses a simple `Form` view, some `@State` properties as well as a property for the item being edited. To access the data controller an `@EnvironmentObject` is used. When initializing the view, the state properties will be filled based on the item given to the initializer.

To synchronize changes a `update()` function is used, which is also triggered by the views `.onDisappear(perform:)` modifier. To update the project or item list when returning `objectWillChange.send()` is called on the project. This is possible thanks to Swift automatically adding `ObservableObject` conformance to any `NSManagedObject` subclass. The reason for calling `objectWillChange.send()` on the project rather than the item is that changing the item completion status also affects the project.

So far nothing is watching the items or projects for changes, this is solved by seperate the `NavigationLink` view of the projects/items list into its own view (`ItemRowView`) and add a property for the item with the `@ObservedObject` wrapper.