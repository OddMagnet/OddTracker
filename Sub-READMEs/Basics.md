# Basics

## Designing a great model

### The model

One of the most important steps when creating a new app is trying to get the data models and access as right as possible early on. Of course this will get refined over time, but good fundamentals make that process much easier.

For this app, there are two types of data to consider for the model:

- An item, which can be any one specific thing or task that is being worked on
- A project, which is a collection of items

For example, a project could be cleaning up the garden, with items being things like trimming shrubs, making a compost and scrubbing down garden furniture.

For this project I added two entities for the two types of data:

- `Item` with the attributes
  -  `title` and `detail`, both as `String`
  -  `priority`, an `Int16` -since Core Data has neither `Enum` nor a simple `Integer` type- to map the priority of the item in the project, with 1 being the lowest and 3 the highest
  -  `isCompleted`, as `Boolean`
  -  `creationDate`, as `Date`
- `Project` with the attributes
  - `title` and `detail`, both as `String`
  - `isClosed` as `Boolean`
  - `color` as `String`, since Core Data does not have a `Color` type
  - `creationDate` as `Date`

The **relationship** between `Item` and `Project` is 'many to one', a single project can contain many items, but each item is only in one project.

### Data access

For data acces the `DataController` class is used, it is responsible for setting up Core Data and handling interactions with it. The reason for using a `DataController` over a 'Singleton' is that the later one is harder to test and it's much harder to ensure a clean slate for every test run.

The `DataController` class conforms to `ObservableObject`, so any SwiftUI view can create and watch an instance of it. The `container` property in it is an instance of `NSPersistentCloudkitContainer`, responsible for loading and managing local data, as well as synchronizing with iCloud.

For preview and testing purposes the initializer has a `inMemory` argument, which defaults to `false`, if set to `true` the data will be created entirely in memory, rather than on disk, meaning it'll disappear when the app is closed. 

Additionally there is a `createSampleData()` method, used for preview and testing purposes as well. One big advantage of using Core Data is the automatic synthesization of classes, in this case `Project` and `Item`, with properties matching the attributes defined in the model.

Finally, for preview purposes, `DataController` contains a static `preview` variable, used like this `SomeView(dataController: DataController.preview)`

To handle interactions with the data, the `save()` and `delete()` methods are used to update and delete single items or projects, while the `deleteAll()` method is used for testing purposes, making sure that there is no other data in memory when `createSampleDate()` is used.

To make the `DataController` usable in the whole project, it is created in the `OddTrackerApp` file (since it contains the `@main` entry point of the app) and then shared as an `EnvironmentObject`, additionally the `viewContext` of the data controller is added to the environment using the `.managedObjectContext` key

### iCloud

To sync information across devices the configuration in Xcode needs to request access to iCloud using CloudKit, for this, the 'iCloud' and 'Background Modes' capabilities are added to the configuration. In 'iCloud' the 'CloudKit' service is enabled and in 'Background Modes' the 'Remote Notifications' mode is enabled. Additionally for the CloudKit service the apps bundle ID is needed so CloudKit knows where in the developer account the data should be stored.

## First Steps in UI

The UI of the app uses a few different tabs:

- Home, for a summary of the user's progress
- Open, for showing open projects
- Closed, for showing closed projects

Programmatically the 'Open' and 'Closed' tab are the same view (`ProjectsView`), with the difference being the data they present. This is accomplished by using its `showClosedProjects` property to filter the fetchrequest for projects. Depending on which tab ('Open' or 'Closed') is selected the property will be either `true` or `false`.

## Cleaning up Core Data

Making a Core Data attribute non-optional only means that it needs to have some value by the time it is saved, while a non-optional property in Swift must always have a value. This can lead to problems, so I 'removed' the optionality from Core Data.

One way to solve this would be removing it by hand, changing the `Codegen` in the model to 'None', then using the 'Create NSManagedObject Subclass' option in the 'Editor' menu and finally editing the code in the files that were generated. This is as simple as removing the `?` from the properties. 

The aforementioned solution is problematic though, since it gives a false sense of certainty. The underlying data might still be nil and would be loaded as nil, forced into a non-nil container and used immediately. 

A better solution (and the one used for the app) is creating custom extensions for `Project` and `Item`, which simply use nil-coalescing to ensure that there is a default value in case a property is nil. Additionally those extensions posess a static `example` property. `Project` also has two computed properties, `projectItems` for easy access to the project's items (sorted by priority, then creation date and putting completed items at the end) and `completionAmount` to quickly get the percentage of completed items.

## Storing tab selection

To store the users tab selection and make it possible to programmatically switch tabs a few things are needed:

- The tabs need tags, this can be anything that conforms to `Hashable`, in case of this app it's a `String?` value coming from the assigned view's static `tag` property
- A property for the selection, `selectedView`, needs to be bound to the TabView, also a `String?` value, corrosponding to the tab's tag
- Both are optional properties, `selectedView` so it can be nil initially and `tag` so that it can be compared to `selectedView`

The static `tag` properties in views is used to avoid hard-coded strings as much as possible, this way there is only one place where the string is hard-coded while everywhere else the static property is used (eg: `ViewName.tag`).

To keep the selected tabs between the apps runs the `@SceneStorage` property wrapper is used for the `selectedView` property. It automatically saves and reads its value to `UserDefaults`.
