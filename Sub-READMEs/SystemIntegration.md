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

To enable local notifications a few steps were needed:

1. Update the UI and Core Data to enable selecting times for notification and storing them

   1. Adding a date attribute to the project entity in the Core Data model, this additional attribute is automatically added to all existing data with a value of nil

   2. Adding two `@State` properties in `EditProjectView`

      - ``remindMe`, as a toggle for the switch that turns notifications on/off
      - `reminderTime`, to store the time when the notification should be triggered

   3. Updating the initializer of `EditProjectView` to set the above properties

      - Adding a section to the form to display the `Toggle` and `DatePicker` views

      - Updating the `update()` method to include `reminderTime`

2. Adding notifications

   1. Adding an import to `UserNotifications` in `DataController` then adding the following methods

      - `addReminders(for:completion:)` which adds a reminder for a given project

      - `requestNotifications(completion)`, a private function that asks for permission for notifications
      - `removerReminders(for:)` which removes all reminders for a given project

      - `placeReminders(for:completion)`, another private function that placed the notification

   2. They're called in the order above, `addReminders()` first checks the permissions and calls `requestNotifications()` if needed. If permissions are granted `placeReminders()` is called next, which actually adds the request to the `UNUserNotificationCenter`. 

3. Adding error handling

   1. If the whole process fails at any point, the completion closure propagates back up to the `update()` method in `EditProjectView`, where it resets the state for reminders and shows an error message
   2. The error message also provides a button that links the user directly to the settings for the app, so the user can enable notifications

4. Adding localization for the new changes

Currently every change in a project re-sets the notification (if one is set), but this is intentional, since otherwise the user might get a notification that contains the old project name. And since the notifications get added with the same identifier they just replace the old one instead of creating a duplicate.

## In-App Purchases

For IAP its extremely important that every one of the following steps is implemented and works correctly, to implement IAP these steps were needed

1. Adding products to buy, this means telling Apple which products should be offered and how much they cost
2. Monitoring the transaction queue. At any point a purchase can happen, so its necessary that the queue is monitored at all times
3. Requesting available products, basically asking Apple for the list of products to show, some products from step 1 might have been rejected from Apple or are not available for other reasons
4. Handling a transaction, when the user has completed a purchase, whether successfull or not, it needs to be handled
5. Handling restoring purchases, to allow the user to share purchases across all his devices, or get them back after reinstalling the app
6. Creating a UI, this is only relevant once all other steps are completed and working properly

### Logic (Steps 1-5)

Luckily this doesn't require nearly as much code as it sounds like, since most of the functionality is provided by `StoreKit`. Like with `DataController` all the code is going to have one central place in `UnlockManager.swift`, which is also created and stored in the main app struct.

For real apps the products would have to be create in 'App Store Connect', for now this app only uses the method used for testing IAPs, which is creating a `Configuration.storekit` file, where new products are simply added via the '+' button. To use this configuration file it needs to be enable in the "Run..." options (⌥⌘R), where it is enable in the 'Options' tab by changing the Storekit configuration from 'None' to `Configuration.storekit`

`UnlockManager` is a class that inherits from `NSObject`, so it can act as `StoreKit` delegates, and conforms to `ObservableObject`, so purchases can be instantly reflected in the UI. Inside it has one nested enum which represents the current state of the purchase as well as a `@Published` property `requestState` to store the current request state and another nested enum for error states.

To watch for purchases on a particular product the following things are needed: 

- Watching for any kind of purchase
- Looking for the (previously added) product
- Preparing and storing the purchase information, for this App this happens in `DataController`, since it is data it should by managed by `DataController`

For this `UnlockManager` has three properties `dataController`, to store purchase information, `request`, to store a request for a product, and `loadedProducts` to store loaded products.

Inside its initializer it store the data controller instance, creates a request to look out for, starts watching the payment queue, sets itself as a delegate for the request and starts it. Additionally a deinitializer is added to remove its own object from the payment queue observer when the app is terminated. Finally, to actually use the `UnlockManager` an instance of it is create in `OddTrackerApp`, stored as a `@StateObject` and injected into the environment.

To store the unlock state a new property is added to `DataController`, `fullVersionUnlocked`, which returns a true or false, depending on if the full version is unlocked. Additonally a check for the unlock state is added to the initializer of `UnlockManager` to avoid watching the queue when the full version is already unlocked.

For it to work as a delegate `UnlockManager` needs to conform to both `SKPaymentTransactionObserver` (to watch for purchases) and `SKProductRequestDelegate` (to request products from Apple), which require the following methods

- `productsRequest(_:didReceive:)`, which is called when the request finishes successfully. It stores the returned products, ensures they were not empty and the product(s) are not invalid. If everything worked out it sets the request state to loaded with an associated value of the  product. This all happens on the main thread, since it adjusts a published property (`requestState`)
- `paymentQueue(_:updatedTransactions:)`, which
  - if the transaction succeeds or is restored: unlocks the purchase and updates the request state to 'purchased'
  - if the transaction fails: attempts to go back to the 'loaded' state if possible, otherwise goes to 'failed' with whatever error occurred
  - if the transaction is deferred (e.g. user needs to ask a parent to authorize), set the state to 'deferred' 

Additionally the following two methods were added: 

- `buy(product:)`, which puts the `SKProduct` into an `SKPayment` that is then added to the `SKPaymentQueue`. iOS then takes over to validate the payment, including the UI for the process
- `restore()`, which simply calls the dedicated `restoreCompletedTransactions()` function on the default `SKPaymentQueue`

Finally, a computed property `canMakePayments` was added, which returns a boolean on whether the user is able to buy IAPs.

### UI (Step 6)

To properly display the prices an extension on `SKProduct` is added, containing a computed property `localizedPrice`, which returns  `String` with a correctly formatted localized price.

Next a custom button style is added, which is used for the 'Purchase' and 'Restore' button, so they stand out from the rest of the app.

The last views added for this are `ProductView`, which shows the product purchasing screen and `UnlockView`, which shows the various states of the purchase. Currently neither of them can be used in SwiftUI previews since it's not possible to simulate a product in there.

Up to this point there was no reason to buy the product, since the user could create unlimited projects, this is changed by adding a check in the `addProject()` function of `ProjectsViewModel`. If the user hasn't unlocked the full version and wants to create a fourth project a sheet is toggled that asks to purchase the full version.

Finally a `appLaunched()` function is added to `DataController`, which is called on app launch by adding the `.onAppear(perform: dataController.appLaunched)` modifier in `ContentView`. This function checks that the user has used the app for a while, then proceeds to request a review

```swift
func appLaunched() {
  guard count(for: Project.fetchRequest()) >= 5 else { return }

  let allScenes = UIApplication.shared.connectedScenes
  let scene = allScenes.first { $0.activationState == .foregroundActive }

  if let windowScene = scene as? UIWindowScene {
    SKStoreReviewController.requestReview(in: windowScene)
  }
}
```

And of course new localization for the changes is added.

## Quick Actions

To add quick actions the app needs an URL type, which is added in the projects configuration, under the main apps target (**OddTracker**), in the **Info** tab under the **URL Types** section.

Next a quick action is registered in the **Info.plist** file by adding a new row with the content of `UIApplicationShortcutItems`, changing it to an array and adding the desired items to it. 3 Keys are added to this array `UIApplicationShortcutItemTitle` for the shortcuts title: 'New Project', `UIApplicationShortcutItemType` with the value that is send to the app 'oddtracker://newProject' and `UIApplicationShortcutItemTitle` for the icon the shortcut should have ' rectangle.stack.badge.plus'.

At the time of writing SwiftUI doesn't have much support for quick actions, so some UIKit is needed. Thanks to the `@UIApplicationDelegateAdaptor` property wrapper it's possible to handle UIKit delegates that SwiftUI can't handle yet. Two classes are created, `AppDelegate` for app-wide announcements and `SceneDelegate` for callbacks in the current scene. Both are then connected toegether with SwiftUI.

`AppDelegate` conforms to the `UIApplicationDelegate` protocol and `SceneDelegate` to the `UIWindowSceneDelegate`. In **OddTrackerApp.swift** a new property is added: `@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate`, so SwiftUI can make use of the classes that were just added.

Next the application delegate needs to know about the scene delegate so it can create a new scene when necessary. This is done with the `application(_:configurationForConnecting:options:)` method of the `UIApplicationDelegate` protocol. It creates a new `UISceneConfiguration` instance, sets the delegate of the instance to `SceneDelegate.self` and returns the configuration.

To access the url that is passed when using the quick action the `SceneDelegate` class gets a new property: `@Environment(\\.openURL) var openURL`. and two functions:

- `windowScene(_:performActionFor:completionHandler:)`. This function gets handed the shortcut that has been triggered and needs to call the associated completion handler with true (for a correctly handled URL) or false (when the URL couldn't be handled). If the URL was handled the `openURL(_:completion:)` function is called.
- `scene(_:willConnectTo:options)`, which is called when the scene is being created. It also checks the URL but has no completion handler. After checking the URL it also calls `openURL()`

In `ContentView` a new function `openURL(_:)` is added, which simply changes the app's tab to the open projects tab, then calls `addProject()` on the data controller. Additionally the `TabView` needs a new modifier `.onOpenURL(perform: openURL)` to call the new function.

Next most of the `addProject()` function which is still in `ProjectsViewModel` is being moved to `DataController`, so it can be called from anywhere. It also gets the `@DiscardableResult` wrapper, so its return value - a boolean, whether or not the `UnlockView` should be shown - can be ignored if needed.

In `ProjectsViewModel` the function is changed to simple call the version of the data controller and check the returned value.

**Note:** this might seem like quite the workaround, since it would've been possible to just call the old (= in `ProjectsViewModel`) function, but when using the quick action while the app is completely closed this can lead to a race condition, where `SceneDelegates` `windowScene(_:performActionFor:completionHandler:)` is called before the scene is created. This is the reason for its second function `scene(_:willConnectTo:options)`, which itself has a problem too: it happens before the actual UI connection has taken place, meaning SwiftUI might or might not have finished its work by the time the function is called. This is the reason the `onOpenURL()` modifier needs to be in `ContentView` and that it needs to call the `addProject()` function in the data controller.

## Shortcuts

With the code that's already written adding shortcuts is basically childs play. It only takes 3 steps:

1. Telling iOS that the app can handle certain kinds of activity
   - Activities are unique identifiers, they are declared in the **Info.plist** file with a key of `NSUserActivityTypes`, a type of array and a unique idenfitifer, 'io.github.oddmagnet.newProject' for this project
2. Telling iOS what data belongs to that activity
   - This is done by simply adding the `.userActivity()` modifier in `ContentView`, passing the unique identifier defined above. In the closure the eligibility for prediction is set to true and the activities title as to 'New Project'
3. Responding to the activity being triggered
   - For this a new function is added in `ContentView`. `createProject(_:)`. which takes an `NSUserActivity`. It changes the apps tab and calls `dataController.openProject()`
   - Also added is the `.onContinueUserActivity(_:perform:)` passing the uinique identifier and calling the `createProject(_:)` function

## Widgets

### Preparation

In order to add a widget to the app a new target was added "OddTrackerWidget", the _Embed in Application_ setting ties the two targets into one app. The "Configuration Intent" box was not checked since the widget currently does not need to provide customizable properties.

The Widget needs a few files from the main app, namely the Core Data model from `Main.xcdatamodel`, its extension from `Item-CoreDataHelpers.swift` and the data controller from  `DataController.swift`. All those files get a membership in the `OddTrackerWidget` target.

Since the current setup would cause Xcode to throw errors about not finding `Award` and `projectTitle` from the data controller, its file is being split up into multiple files (`DataController-Reminders.swift` and `DataController-Awards.swift`) and moving the respective code into them.

To share the user data between different parts of the app **app groups** are utilized. This is accomploshed by adding the "App Groups" capability in the "Signing & Capabilities" tab of the "OddTracker" targets settings. In the newly added section a new group is added: "group.io.github.oddmagnet.OddTracker". This process is then repeated with the widget extension target. this time however selecting the existing group instead of adding a new one. Now both parts of the app can read and write from shared data.

Next Core Data needs to save its live data into the shared data area of the app group. In `DataController` the initializer is changed to redirect Core Data to use the app group's container.

```swift
let groupID = "group.io.github.oddmagnet.OddTracker"
if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
	container.persistentStoreDescriptions.first?.url = url.appendingPathComponent("Main.sqlite")
}
```

Now the last change in `DataController` is to tell it to automaticall refresh widgets when data has changed. An import for `WidgetKit` is added and the `save()` method is updated to call `WidgetCenter.shared.reloadAllTimelines()` after data is saved.

### The first widget

Now the actual widget can be coded. The template file already provides some things:

- `Provider`, a struct conforming to `TimeLineProvider`, it determines how data for the widget is fetched
- `SimpleEntry`, a struct conforming to `TimeLineEntry`, it determines how data for the widget is stores
- `OddTrackerWidgetEntryView`, the view that determines how the widget looks
- `OddTrackerWidget`. a strict conforming to `Widget`, it determines how the widget should be configured
- `OddTrackerWidget_Previews`, so the widget can be previewed in Xcode

The first widgets `SimpleEntry` only contains two properties, one for a `Date` and the other for an array of `Item`. The date isn't relevant to the widget, since it always shows the next item from _Up next_, but it is a requirement of the `TimelineEntry` protocol. The preview provider and the `placeholder(_:)` function simply use the example item via `Item.example`.

The `getSnapshot()` and `getTimeline()` functions on the other hand need actual `Item` data. The first one is called when iOS needs the current status of the widget, the later when iOS wants to know the future statuses. For the first widget both methods practically will be doing the same, providing the current higest item from _Up next_.

For this a new function is added in `DataController`: `fetchRequestForTopItems(count: Int) -> NSFetchRequest<Item>`. From `HomeViewModel` the code for creating a fetchrequest is moved over and replaced by a call to the newly added function. 

Since the widget itself should know as little as possible about `DataController` - meaning it should not be the one executing the fetch request - another function is added, which simply returns a generic array `results<T: NSManagedObject>(_:) -> [T]`. Now the widget can create an instance of `DataController`, get the fetchrequest and let the datacontroller instance execute it to get the items it needs. This is done in the `loadItems() -> [Item]` function that is added to the widgets `Provider` struct.

Now both `getSnapshot()` and `getTimeline()` can make use of the new `loadItems()` function. The later one is by default called again and again by iOS to automatically reload the timeline, but since this isn't needed a reload policy of `.never` is used. The last step for this first widget was the creation of a simple UI to show the first item from _Up next_, or "Nothing!", when there is none.

### Another widget

Since the current widget has the `@main` entry point it is the only one supported currently. To be able to add multiple widgets a new type that describes several widgets at the same time is needed.

This is done by adding a new 'OddTrackerWidgets' struct that conforms to `WidgetBundle` and moving the `@main` attribute to it. Inside the new struct then is a `body` property, similiar to what a `View` usually has, but this time of the type `some Widget`. The body then contains all widgets the app supports.

To prepare for the next widget the `Item` fetch limit was increased, the `Colors.xcassets`, `Project-CoreDataHelpers` and `Sequence-Sorting` files were added to the widgets target. The new widget itself then just made use of the same `Provider` and `SimpleEntry` structs as the first widgets, but with a different UI, so it could show more entries. The new widget also utilizes the `widgetFamily` and `sizeCategory` environment variables to dynamically adjust how many entries it shows. Lastly the code was separated, `Provider` and `SimpleEntry` were moved into their own file `DataProvider.swift` and both of the widgets got their own files as well, `SimpleOddTrackerWidget.swift` and `ComplexOddTrackerWidget.swift`.
