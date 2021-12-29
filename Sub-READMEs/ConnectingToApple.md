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



### Cleaning up Cloudkit

