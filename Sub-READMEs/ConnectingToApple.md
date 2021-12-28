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



## Adding Sign in with Apple



## Posting comments through Cloudkit



### Cleaning up Cloudkit

