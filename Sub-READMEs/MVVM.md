# Pragmatic MVVM

The next big change for this project is the conversion to the MVVM pattern. This part of the READMEs describes the changes made to some of the views and why not every view is converted. In other words, MVVM is used pragmatically.

Different from MVC, MVVM has a so called "presentation model", which stores the state of the app independent of the UI. It is a class that represents a view fully, but without actually creating any views. This is a huge help for testing, since it can be fed any data and its response can easily be checked. The "glue" between the presentation model and the views in SwiftUI are data bindings.

## ProjectsView (example approach)

The conversion begins with the most important view of the app. Step by step the following was done:

1. Adding a new file, the view's model, `ProjectsViewModel`, this explicitly keeps the `Foundation` import and has no `SwiftUI` import, it gets a `Core Data` import however
2. Adding an extension on `ProjectView` which contains a `ViewModel` class that conforms to `ObservableObject`, this way the name _ViewModel_ can be used freely, since its nested inside `ProjectsView`
3. Moving code to the new `ViewModel` class:
   1. the  `addProject()`, `addItem()` and  `delete()` functions
   2. the `sortOrder`, `showClosedProjects` and `projects` properties
   3. the initializer
4. Deleting the `@EnvironmentObject` properties `dataController` and `managedObjectContext`, since they're no longer needed
5. Adding a property to instantiate and store the viewmodel for the view `@StateObject var viewModel: ViewModel`
6. Cleaning up the code in the new `ViewModel` class of `ProjectsViewModel`
   1. Adding a temporary import to `SwiftUI`
   2. Adding a property for the `DataController`
   3. Passing in the `DataController` instance in the initializer
   4. Fixing `addProject()` and `addItem()` to get the `context` from the newly added `dataController` property
   5. Removing the `withAnimation()` modifiers from `addProject()` and `addItem()`, this will be added again later
   6. Removing the `@State private` part of the `sortOrder` property
7. Cleaning up the code in  `ProjectsView`
   1. Adding  `viewModel` where it's needed, e.g. changing `projects.wrappedValue` to `viewModel.projects.wrappedValue`, etc.
   2. Adding a new initializer to `ProjectsView`, which creates the viewModel and passes the `DataController` instance and the `showClosedProjects` argument
   3. Changing how `ProjectView` is initialized to the new intializer method in the `previews` struct and in `ContentView`
8. Removing the temporary `SwiftUI` import that allowed the code to compile
9. Fixing the `projects` property 
   1. `@FetchRequest` does not work outside of views, the solution is `NSFetchedResultsController`, which does work outside of views and also helps keep the data updated as things change
   2. Adding a `projectsController` property: `private let projectsController: NSFetchedResultsController<Project>`
   3. Changing the `projects` property to be published: `@Published var projects = [Project]()`
   4. Updating the initializer
      1. Creating a `NSFetchRequest`, adding `sortDescriptors` and `predicate` to it
      2. Wrapping the `NSFetchRequest` in an `NSFetchedResultsController` and assign it to `projectsController`
      3. Setting the viewmodel class as the delegate of the fetched results controller
      4. Adding conformance to the `NSObject` and  `NSFetchedResultsControllgerDelegate` protocols to the `ViewModel` class
      5. Adding the call to `super.init()` before the line that sets the delegate
      6. Finishing the initializer by executing the fetch request and assigning it to the `projects` property
   5. Fixing the access to `projects` in `ProjectsView` from acting as if it was a `FetchRequest` to using it as a simple array, e.g. changing `viewModel.projects.wrappedValue` to `viewModel.projects`
10. Implementing the `controllerDidChangeContent()` method in the `ViewModel` class, to get notified when the data changes
    1. Pulling the updated data and assigning it to the `projects` array 
11. Re-adding `withAnimation()` in `ProjectsView`, one in the `Button` for adding a project and one one around `viewModel.addItem(to:)`

Even after changing so much code around, all the tests still pass.

## More views (general approach)

Instead of listing all steps made for all viewmodels created, this part will only focus on the general approach and thoughts on why things were changed or not changed.

### HomeView

Another view that makes sense to convert is the `HomeView`, it goes by the same general steps of creating an extension on the view, with a `ViewModel` class and moving code over to it, then  fixing/changing what needs to be fixed/changed so it works again. Additionally the viewmodel for `HomeView` works with two fetched results controllers and will expose parts of the data as computed properties for a cleaner call site.

The viewmodel gets the properties `projectsController` and `itemsController`, to fetch the data, and `projects` and `items` as `@Published` properties. As before the `projectsController` and `itemController` properties need to be created in the initializer and assigned. They both also need delegates and calls to `performFetch()` to get the data from Core Data.

Where this viewmodel starts to differ from the previous one is the implementation of `controllerDidChangeContent()`, in that it checks which data (project or item) has been changed and only updated accordingly. Additionally a couple of computed properties are added, `upNext` and `moreToExplore`, which are used for the sections of the same name in `HomeView`. The last thing added to the viewmodel is the `addSampleData()` function, which does exactly what its name suggest.

Now that the viewmodel is complete, all that remains is updating the view it belongs to, `HomeView` for this viewmodel. Creating an initializer that passes the `DataController` instance to and instantiates the `viewModel` property, updating the `previews` struct and fixing compile errors that were brought on by the moving of properties from the view to its viewmodel.

To fix the `ItemListView` used in `HomeView` its `items` property needs to be changed from the `FetchedResults<Item>.SubSquence` type to the `ArraySlice<Item>` type, which is what gets passed when using the computed properties `upNext` and `moreToExplore` from the viewmodel.

### ItemRowView

For the `ItemRowView` the benefits of MVVM are not quite as clear cut, it's still an improvement (testability), but at the cost of a lot more code.

Again a model `ItemRowViewModel.swift` with an extension on `ItemRowView` and a class `ViewModel` is created. This time the viewmodel doesn't need to created fetched results controllers, since it isn't loading any data directly - it only gets passed the item and its associated project -, so it only needs to stash the data.

The viewmodel gets two regular properties, `let project: Project` and `let item: Item`, and an initializer to set them. Additionally the code of the two existing computed properties of `ItemRowView` is moved to the viewmodel.

The Problem with `ItemRowView` now becomes visible, since those two computed properties return preconfigured views, this should not happen in the MVVM pattern. To fix this the `label` property gets changed to only return a string and the `icon` property gets split into two properties, `icon` and `color`, which both return a string, with the later having an optional return value to represent no color.

Additionally, so the view doesn't have to reach into the underlying model, a `title` property was added, which simply returns the title of the item. This might seem like unnecessary code, but it makes it easier to look at, makes it consistent with the MVVM pattern and won't be a problem for performance, since the Swift compiler will remove the extra property anyways, aka. this is just for the programmers eyes.

Finally, the `ItemRowView` needs to be updated, removing the `project` property and replacing it with one for the viewmodel: `@StateObject var viewModel: ViewModel`, adding an initializer to set up the model and updating the properties in the view..

### Where MVVM is less useful

Some of the views where the MVVM pattern is less useful or even becomes more of a disadvantage include:

- `AwardsView`, since its properties are either already outside the view (`Awards.allAwards`), or relate to the view (`selectedAward` and `showingAwardDetails`). The only thing worth moving would be the data controller, which would need the `hasEarned(award:)` function wrapped in the viewmodel so that `getAwardAlert()` can be called. Additionally there'd still be a need to use optional `map()` to display the award color. All in the added complexity outweighs the benefit in my personal opinion.
- `ProjectHeaderView`, since it would practically only store a project and send back its values. But the view would still need to also store the project so it can show it in the `NavigationLink` destination. Adhering to the MVVM pattern for this view would create practically no benefit.
- `EditProjectView`, since it has the same problem that `ProjectHeaderView` does.
