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

To sync information across devices the configuration in Xcode needs to request access to iCloud using CloudKit, for this, the 'iCloud' and 'Background Modes' capabilities are added to the configuration. In 'iCloud' the 'CloudKit' service is enabled and in 'Background Modes' the 'Remote Notifications' mode is enabled. Additionally for the CloudKit service the apps bundle ID is needed so  CloudKit knows where in the developer account the data should be stored.

## First Steps in UI



## Storing the code safely



## Cleaning up Core Data



## Storing tab selection



