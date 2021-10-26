# Editing Data

## Editing Items

Displaying projects and items alone is rather useless without a way to add and edit them, so next is the `EditItemView`

This view uses a simple `Form` view, some `@State` properties as well as a property for the item being edited. To access the data controller an `@EnvironmentObject` is used. When initializing the view, the state properties will be filled based on the item given to the initializer.

To synchronize changes a `update()` function is used, which is also triggered by the views `.onDisappear(perform:)` modifier. To update the project or item list when returning `objectWillChange.send()` is called on the project. This is possible thanks to Swift automatically adding `ObservableObject` conformance to any `NSManagedObject` subclass. The reason for calling `objectWillChange.send()` on the project rather than the item is that changing the item completion status also affects the project.

So far nothing is watching the items or projects for changes, this is solved by seperate the `NavigationLink` view of the projects/items list into its own view (`ItemRowView`) and add a property for the item with the `@ObservedObject` wrapper.

## Instant sync and save

The problem with calling `update()` when the `EditItemView` disappears is that at that it is only triggered when the view has already fully moved offscreen.

One way to solve this would be to use the `.onChange(of:)` modifier on every value of the item and calling `update()` in its closure. While this solution is SwiftUI native, it is rather unpleasant to use when there are many values to monitor.

For a better solution an extension on `Binding` is used. In the extension a new function, `func onChange(_ handler: @escaping () -> Void) -> Binding<Value>` is used, where `handler` accepts a function that returns nothing. Inside the function a new instance of `Binding` is created, whose getter simply returns the wrapped value, while its setter, in addition to setting the new value, also calls `handler()`. 

With this in place `onChange(update)` can be added to all bindings in the `EditItemView`. While this is not a lot more pleasant than the previous solution, it solves the problem of having to write a closure for every `onChange(of:)` call.

Finally, since the changes are now reflected instantly in the UI, the saving needs to be handled. Items should be changed when the user returns to the project list or exits the app after editing an item. For the first situation using the `onDisappear()` modifier to save changes (call `dataController.save()`) is good enough. For the second situation it's necessary to watch when the app is being moved to the background.

 The second situation is solved in the `OddTrackerApp.swift` file by using the `.onReceive()` modifier and watching for the `UIApplication.willResignActiveNotification` notification, this tells the app to watch for when it goes into the background and makes it possible to run some code before it does go into the background. Since the `perform` argument expects a function that receives a `Notification` it is not possible to directly call the data controllers `save()` function, instead a shim method `save(notification: Notification)` is used, its only purpose is the call `dataController.save()`.

## Editing projects

Editing projects is rather similiar to editing items, aside from the use of `LazyVGrid` to display selectable colors, in a `ZStack` so the current color can be marked, and `.onTapGesture` modifier to update the selected color.

The saving is handled just as it is in the `EditItemView`, but the deleting of a project gets an extra confirmation so projects don't get deleted by accident. This is accomplished by having the delete button only toggle the `showDeleteConfirm` state, which triggers an `.alert()` modifier. Only when the user confirms the `delete()` function is actually called.