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

Lorem ipsum

## Shortcuts

Lorem ipsum

## Widgets

Lorem ipsum
