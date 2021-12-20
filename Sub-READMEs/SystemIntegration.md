# Integrating with the system

## Haptics

At the point of writing custom haptics were added for the closing of a project in `EditProjectView`. For this a `CHHapticParameterCurve` and two `CHHapticEvent`s are created and fed to a `CHHapticPattern`, which itself is given as an argument of the `makePlayer(with:)` function of the `CHHapticEngine` instance.

## Spotlight

Spotlight is a feature that's rather easy to implement and extremely useful for users at the same time, so of course this app needs to have it too.

This is implemented in `DataController`, to keep it in a central place for easier upgrades in the future. Writing an item to spotlight is done in the `update(_:)` method and consists of 4 steps:

1. Creating a unique identifier. When updating an item the same identifier is used
2. Deciding what attributes to store in Spotlight, for now this is only the `title` and `contentDescription` attributes
3. Wrapping identifier and attributes in a spotlight record and passing a domain identifier as a way to group items together
4. Sending that packet to Spotlight for indexing

The unique identifier and domain identifier are created by calling `.objectID.uriRepresentation().absoluteString` on the item and project respectively. For the `title` and `contentDescription` attributes the items title and detail are used.

All this is used to create an `CSSearchableItem` instance, which is then passed to Spotlight via `CSSearchableIndex.default().indexSearchableItems([searchableItem])`

Finally, the saving for data is changed, instead of calling the `save()` function of `DataController` directly, the `update(_:)` function is called, which, after updating Spotlight, calls the `save()` function.

### Launching to an item

To launch the app to an item selected in Spotlight a few more changes are needed. This requires 3 steps:

1. Figure out the selected Object, for this the `item(with:)` method is added to `DataController`, it

   - takes a `String` that represents the unique identifier of an item and creates a `URL` from it

   - Checks if there is an object for the url by calling `container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url)`

   - returns the item with the corrosponding id

2. Present the item in an `EditItemView`, activated from the `HomeView`, for this

   - a new `selectedItem` property and a `selectItem(with:)` method to get and set the selected item is added to `HomeView`s ViewModel

   - in `HomeView` `CoreSpotlight` is imported and the `.onContinueUserActivity()` modifier is used to call the beforementioned `selectItem(with:)` method

   - in `HomeView`, a `NavigationLink` to an `EditItemView` with the selected item is created and shown once the item is set

     - ```swift
       if let item = viewModel.selectedItem {
         NavigationLink(
           destination: EditItemView(item: item),
           tag: item, 														// tag and selection ensure the view is only
           selection: $viewModel.selectedItem,		// triggered when the selection binding changes
           label: EmptyView.init
         )
         .id(item) // ensure the view is refreshed when the item changes
       }
       ```

3. Ensure the `HomeView` is actually visible when a Spotlight item is selected. this is done by

   - adding a function (`moveToHome(_:)`) that adjusts the selected tab to the Home view when a Spotlight launch is detected
   - using the `.onContinueUserActivity()` modifier on the `TabView` of `ContentView` to call the `moveToHome(_:)` function

### Removing old data

Lastly, old data needs to be removed from spotlight when the user removes an item or even a whole project. For this the `delete(_:)` function in `DataController` is updated to remove items from Spotlight when an item is deleted and remove all items of a project, when a project is deleted.

## Local Notifications

Lorem ipsum

## In-App Purchases

Lorem ipsum

## Quick Actions

Lorem ipsum

## Shortcuts

Lorem ipsum

## Widgets

Lorem ipsum
