# Connecting to Apple

## Upgrading iCloud

Before most things in this chapter, some preparation and clean-up needs to be done. The "Key-Value Storage" service is added in the Apps Signing & Capabilities setting, under the iCloud capability. This is similiar to `UserDefaults`, but in the Cloud. The other capability that is added is "Sign in with Apple".

Next there are some changes to ensure the data syncs correctly across devices. First the "Used with CloudKit" box is checked for the "Default" configuration of the data model, via the Data Model Inspector. The other change needed for this is to tell the `viewContext` in `DataController` to automatically merge changes from other devices. This is done in the `loadPersistentStores()` function after the check for errors is passed: `self.container.viewContext.automaticallyMergesChangesFromParent = true`

Lastly, before adding more functionality some bugs were addressed:

1. New project items won't always appear in the "Home" tab
2. Renaming an item won't always change its name in the "Home" tab
3. Calling `deleteAll()` successfully deletes all projects and items, but it only shows after a relaunch

### Adding items

To make new items appear in the "Home" tab they need a default value for the `completed` property, otherwise the computed properties won't return those items. A simple change in `ProjectsViewModel` is all that's needed to fix this bug.

### Renaming items

Changes made on items aren't reflected in the "Home" tab because SwiftUI thinks the data is constant (`let items: ArraySlice<Item>` in `ItemListView`), so that is changed to a `@Binding`. This creates some more errors that need fixing, first the items passed to the `ItemListView` are updated to pass a binding by adding a `$`. Since `upNext` and `moreToExplore` are computed properties SwiftUI can't detect when they change, so they are changed to `@Published` properties and their values are changed to update in the initial fetch requests as well as in the updating of the fetched results controller.

### Deleting everything

The last bug being fixed happens because Core Data runs the batch delete on the persistent store, but doesn't update the managed object context reading of the store.  For reusability a new private `delete()` function is added, which takes a `NSFetchRequest` and deletes all objects that would be returned by said request. It then checks the results of `container.viewContext.execute(/*batchdelete*/)`, reads the IDs of the delete objects and merges them into the live view context.  Then the previous `deleteAll()` method is updated to use the new private `delete()` function.

After those changes the bug is mostly fixed. The projects don't always disappear from the "Home" tab. This last part is fixed by updating the `controllerDidChangeContent(_:)` function in `HomeViewModel` to always update both the `items` and `projects` arrays.

## Storing data in iCloud

For this next part the app is changed from relying on iCloud to sync data to using CloudKit. This is a subtle difference, iCloud is built on top of CloudKit, with iCloud syncing can be done with very little effort, but sharing isn't really a possibility. In order for the app to be able to share tasks with other users the app needs to be able to manually handle data stored in the cloud.

To be able to send data to iCloud a few steps are needed:

1. Importing CloudKit
2. Creating a unique persistent identifier for the data, so the same thing won't get uploaded multiple times
3. Creating a `CKRecord` instance for a project, along with instances for all items belonging to the project
4. Linking the data together, so that items belong to projects
5. Sending the data to iCloud and watching for potentiel errors

The first four steps are really all about converting Core Data information to CloudKit information and making sure its the right information. Currently there is no plan to upload a projects color, reminder times or other information that isn't needed when sharing projects, because of this the "selected information" - what the app should upload to iCloud - doesn't match Core Data 1-to-1. Additionally some new information will be added, the name of the user that uploaded a project.

To convert all this data a new helper function to convert the data is added in `Project-CoreDataHelpers.swift`,  `prepareCloudRecords()`, which returns an array of `CKRecord`. It creates a `CKRecord` for the project, adds the keys and values that should be stored in the Cloud, then creates an array of `CKRecords` for all the items belonging to that project, again with all needed keys and their respective values, then adds the project at the end of the array and returns it.

Now the data is ready and it's time to start communicating with iCloud, this means:

1. Telling CloudKit that the app wants to modify some records, passing the records it just created
2. Telling CloudKit how to handle differences, e.g. that it should overwrite existing data
3. Adding a completion closure which is run  once all records are saved. This is being passed the records that were created/deleted and potential errors that occured
4. Sending the data off to iCloud

First the app gets a simple toolbar button in `EditProjectView`, since users are already reading/changing theprojects data in that view. The button prepares the records with the previously added function, creates a `CKModifyRecordsOperation`, sets the operations `savePolicy` and `modifyRecordsCompletionBlock`, then adds it to `CKContainer.default().publicCloudDatabase.add(operation)`.

## Querying data from iCloud

Before any data can be queried from iCloud a few models are created, `Loadstate` to represent the current state of the request for data as well as `SharedProject` and `SharedItem` to store the received data.

Next a rudimentory view, `SharedProjectsView` is created, currently is doesn't do much more than store loaded projects, the loading state and show either a `ProgessView`, some text or a `List` view for the loaded projects, where the `NavigationLink`'s are currently placeholders. 

With the `.onAppear()` modifier a function `fetchSharedProjects()` is called, which does exactly what the name implies. It:

- checks that the `loadState` was `.inActive` first, this is to ensure the function doesn't run constantly when the user tabs through the app
- creates a `CKQuery` that gets all Project records, sorted by their creation date (**Note**: the "creationTimestamp" had to be manually added and set to "Sortable" in the iCloud Dashboard)
- creates a `CKQueryOperation`, filled with the above query and sets the `desiredKeys` and `resultsLimit` properties of the operation
- sets a closure for the `recordFetchedBlock` property of the operation
  - The closure takes the data from the record and converts it to a `SharedProject`, then adds it to the `projects` property of the view and sets the loading state to `.success`
- sets a closure for the `queryCompletionBlock` property of the operation
  - The closure simply checks if the `projects` property of the view is empty and if it is sets the loading state to `.noResults`
- sends off the operation to iCloud

Next another rudimentory view, `SharedItemsView` is created, it works much the same as the `SharedProjectsView`, displaying Items instead of Projects. The `NavigationLink`s in are now updated to link towards the `SharedItemsView`. The view itself also has a function to fetch items, much like the previous function to fetch projects. Where it differs is in the creation of the query, since it adds a predicate to only fetch items belonging to a project, like this:

```swift
let recordID = CKRecord.ID(recordName: project.id)
let reference = CKRecord.Reference(recordID: recordID, action: .none)
let predicate = NSPredicate(format: "project == %@", reference)	
```

## Adding Sign in with Apple

The following things are needed to add "Sign in with Apple":

1. Telling the system what data the app wants to read
2. Responding to a successfull sign in by storing the user's data
3. Responding to a failed sign in
4. Building some UI that explains the sign in button
5. Presenting the sign in button at an appropriate time

First a view, `SignInView` is added, it displays information based on the current sign in state. The `presentationMode` environment variable is used to dismiss it, the `colorScheme` environment variable is used to ensure the "Sign In with Apple" button also looks good in dark mode.

Next two functions are added:

- `configureSignIn(_:)`, which (currently) only sets the `.requestedScopes` property of the request
- `completeSignIn(_:)`, which takes the result, checks for success or failure
  - on success it tries to create the username from the data it got, if there is no name data it creates a random username
  - if the sign in was successfull, but the Apple ID could not be typecasted, it sets the status to `.failure(nil)`
  - on failure it checks if the user cancelled, if so it sets the status to `.unknown` and returns. If there is another reason it sets the status to `failure(error)`

A few more changes were made to finish this step. `EditProjectView` got properties read the username from `@AppStorage` and to show the `SignInView` as a sheet. The `prepareCloudRecords()` function from `Project-CoreDataHelpers` now takes a string argument for the owner/username. Last but not least the button for the iCloud upload in `EditProjectView` has its code moved to a seperate function `uploadToCloud()`, with an added check for the username, showing the `SignInView` sheet if there is none, otherwise uploading the data to the cloud.

To better test the app in the simulator an environment check was added in `OddTrackerApp`, which ensures there always is a username if the app runs in the simulator.

## Posting comments through Cloudkit

As with `SharedProject`/`SharedItem` messages also need a model, this is added with `ChatMessage`, with an additional initializer that takes a `CKRecord`, since messages will always be created from one.

Then a few new properties are added to `SharedItemsView`, an array to store the messages, a `@AppStorage` property to access the username and two `@State` properties, one to store the new message text before it is send off and the other to toggle the `SignInView`, with the needed `.sheet()` modifier.

Next a function `sendChatMessage()` is added, which checks that there is text and username, create a record from it, adds a reference to the project and sends it all off to the cloud. Should there be an error the text for the new message is reset, otherwise it is simply emptied. On success it also creates a `ChatMessage` from the record, so that it can be added to the array of messages and the UI can update instantly.

For now there is only a rudimentary UI added to display chat messages (or a sign in button if the user isn't so far), as a footer section to the list of items of the project.

The last step of this part is adding a bit more UI to display messages once they're fetched. To get the messages a function `fetchChatMessages()` is added, which works much likes the `fetchSharedItems()` message. It checks and sets the loading state, creates a `CKQuery`, a `CKQueryOperation` from that query, adds the `recordFetchedBlock` and `queryCompletionBlock` and sends it off to the cloud.

## Cleaning up CloudKit

As usual, first comes making the new functionality work, then comes making it work well and cleaning out bugs.

One thing that doesn't work well is that the upload icon keeps showing for projects that are already in the cloud. It's also not possible to remove projects from the cloud yet. So the next steps are to write something that checks whether a project already exists in the cloud, something to remove a project and its items from the cloud and something to update the button, depending on the projects status in the cloud.

### Checking an objects cloud status

One possible way of checking for a projects existence in the cloud would be `fetch(withRecordID:)`, but this method runs as a low-priority task, so it's not the best fit for a quick check. Instead a `CKFetchRecordsOperation` is used, it works similar to `CKQueryOperation`, but instead of a filter it searches by a given record ID. The reason this is faster is that iCloud is automatically adding a queryable index for records, meaning they can be found by their ID very quickly. Another optimisation possible with `CKFetchRecordOperation` is the `desiredKey` property, setting it to `recordID` means that CloudKit will return nothing but the ID.

Another thing that can be changed is the way the data that is being received is handled. Instead of providing a closure for `recordFetchedBlock` it's possible to simply use a completion block for the whole operation. This isn't possible with `CKQueryOperation` since it can send back lots of data, but `CKFetchRecordsOperation` will only send back requested IDs, or in the case of this app, just a single one.

This is handled by the `checkCloudStatus` in the extension `NSManagedObject-CheckCloudStatus`, this could've been done in the extension to `Project` in `ProjectCoreDataHelpers`, but since this is a generally helpful functionality it gets its own extension.

### Changing a projects cloud status

To change the status of a project in the cloud some preparation is needed. First the `EditProjectsView` gets an enum for the possible states (`checking`, `exists`, `absent`) and a property `cloudStatus` to keep track of the state. A function `updateCloudStatus()` is added to update the property. `uploadToCloud()` is changed to include a call to the `updateCloudStatus` function. `removeFromCloud()` is added and does what the name implies, in addition to also calling the `updateCloudStatus()` function.

The last change needed was adding the UI to make use of the new functionality.

### Error handling

Last but not least, the handling of errors. Network operations are far more likely to throw errors than most other things, but luckily, baked into the API, there are errors being thrown, making it easy for developers to start handling them. 

First a new extension on `Error` is added, `Error-CloudKitMessage`, with a function `getCloudKitError()` which really is just a simply switch-case to go over different possible error codes and return a more helpful string to display for the user.

Next both the `uploadToCloud()` and `removeFromCloud()` functions are updated to use the previously added `getCloudKitError()` function to set a new `@State` property, `cloudError`. 

Sadly just showing an `Alert` with the `.alert()` modifier doesn't work, this is because `String` doesn't conform to `Identifiable`. It's possible to make it conform, but that would likely not be worth the effort and could even cause problems in the future.

Instead a wrapper for the error string is created with `CloudError` which now conforms to `Identifiable` and `ExpressibleByStringInterpolation`, which means that it can be used for the `Alert` since it has a computed `id` property that just returns the `message` property.

Additionally the from the previously mentioned extension is used to create a second initialiser, so it's now possible to create a `CloudError` instance from just an `Error`.

With all this in place, it can now be used in the various places where such an error might occur: `removeFromCloud()`, `uploadToCloud()`, `fetchSharedItems()`, `fetchChatMessages()`, `sendChatMessage()` and probably some more in the future.

