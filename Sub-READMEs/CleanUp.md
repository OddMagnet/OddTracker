# Cleanup

At this point all of the basics are working, now comes accessibility, documentation, project structure and more.

## Accessibility

First comes Voice Over, by default Voice Over makes the app more accessible, but there are still things that can be done better. Grouping elements into one with the `.accessibilityElement()` modifier for example makes the home view much easier to navigate with Voice Over, setting before mentioned modifier to ignore children and combining it with the `.accessibilityLabel()` modifier to provide a custom label makes it even better. In the projects view the `.accessibilityElement()` modifier is also used to combine the `HStack` in the `ProjectHeaderView`

For basic controls Voice Over works just fine, for some custom controls, like the colors displayed in the `EditProjectView`, it does not, those are unavailable without adding some modifiers. Hiding the Stack with `.accessibilityElement()`, followed by adding some traits with the `.accessibilityAddTraits()` and localizing the color names with an `.accessibilityLabel()` does the trick.

Finally, to fix some small labeling problems the award buttons in `AwardsView` get a `.accessibilityLabel()` that even tells the user that the award is unlocked and its name, or that its locked. Additionally the awards description is given. `ItemRowView` gets a computed property `label` which is used in the `.accessibilityLabel()` for the `NavigationLink()` views, so every item will have a fitting description. 

## Cleaning up view code 

Before SwiftUI, View Controllers in the MVC design pattern were troublesome, since they'd often amass such amounts of code that people started joking about MVC standing for 'Massive View Controller', now in SwiftUI the same can be said about the views, not only are they used to organize the apps layout, they're often also packed with functionality to bring said layouts to life. Just as 'Massive View Controllers' were undesirable in the MVC pattern, so are huge views in SwiftUI.

To remedy this, the views get trimmed by splitting up the `body` property:

- performing calculations outside of it, so it remains fixed (seperating layout logic from computation logic)
- splitting the layout inside the `body` property into multiple standalone views

Specifically this means that the `HomeView` gets a computed property `label` for the accessibility label, the `list()` method gets extracted to its own  `ItemListView` and the cards that summarize projects to the `ProjectSummaryView`.

`ProjectsView` gets several functions for actions attached to buttons and tap gestures, `addItem(to:)` for the button to add new items to projects, `delete(_:from:)` for the `onDelete()` modifier that is attached to the `ForEach` view and `addProject()` for the new project button. Additionally the layout in the `if` statement at the top of `body` gets moved into a computed property `projectsList`, clearing up its functionality. Finally the toolbar items get computed properties for their layout, `addProjectToolbarItem` and `sortOrderToolbarItem`.

`EditProjectView` also get a change, the `LazyVGrid` showing possible colors for a project is turned into a `colorButton(for:)` function. This is chosen over a concrete view, the later would mean syncing state and making sure `update()` gets called correctly, which doesn't necessary make the code clearer / easier to read.

## Handling localized strings

Just some notes and examples on how to possible handle localized strings in a bigger app. 

For the process of generating strings, it's possible to make use of the `tableName` and `comment` parameters of `Text`'s initializer. `tableName` is used to specify which strings file the localized string should be read from, by default SwiftUI chooses `Localizable.strings`, `comment` is used to add comments to describe the string, which will then appear in the generated files.

One very simple solution to improve localized strings would be to use screaming snake case, e.g. `WELCOME_MSG` and then use that string in the `Localizable.strings` files, this clearly makes text as not translated when it's visible in the app, while also shortening the strings, reducing errors in the localization files.

A better solution would be to remove strings entirely from the code by switching to enums, held in their own file, so all strings are in the same place.

```swift
// Strings.swift
import SwiftUI

enum Strings: LocalizedStringKey {
  case appWelcomeMessage
  case updateSettings
}

extension Text {
  init(_ localizedString: Strings, tableName: String? = nil) {
    self.init(localizedString.rawValue, tableName: tableName)
  }
}

// Usage:
Text(.appWelcomeMessage)
```

This way its impossible to mistype a string and every localized string is in one place. 

## Cleaning up Core Data

To this point the app had a serious bug. Deleting projects worked fine, but when viewing the Home view, the items from the deleted projects still show up. This happens because so far deleting a project only deletes the project, but not the items belonging to that project.

For this purpose, Core Data has **delete cascase**, which is disabled by default to prevent accidental data loss. For this app however, it makes sense. Enabling it is done by simply selecting the `items` relationship of the `Project` entity in the Core Data model and setting the Delete Rule in the Data Model Inspector to 'Cascade'. The `project` relationship of the `Item` entity however remains as 'Nullify', otherwise deleting an item would also delete the project and all other items in it.

Another problem in the Home View is that is might show high-priority items from closed projects, this happens because closing a project doesn't mean its items will be completed. To fix this another predicate needs to be added, the item must *not* be completed and the project must *not* be closed. It's possible to accomplish this with one predicate: 

```swift
request.predicate = NSPredicate(format: "isCompleted = false AND project.isClosed = false")
```

But for this app, a `NSCompoundPredicate` is used, because its easier to change parts of the predicates or add another one and it makes the intention clearer

```swift
let completedPredicate = NSPredicate(format: "isCompleted = false")
let openPredicate = NSPredicate(format: "project.isClosed = false")
let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [completedPredicate, openPredicate])

request.predicate = compoundPredicate
```

## Adding a linter

Clean code is much nicer to look at and can also be easier to read. To ensure that the code style stays consistent a linter is installed and added to the project. Installation is handled with [brew](https://brew.sh): `brew install swiftlint`, then a `.swiftlint.yml` file is created and the rules for the linter are adjusted for personal preferences.

Then Xcode is configured to run SwiftLint automatically on every build, via a custom build phase. This is done by selected the project in the Project Navigator, selecting the `OddTracker` target and then the Build Phases tab. A new 'Run Script' phase is now added via the '+' button, named 'SwiftLint' and containing the following script:

```shell
# On Apple Silicon Macs SwiftLint is installed in /opt/homebrew/bin instead of /usr/local/bin, hence the alias
alias swiftlint="/opt/homebrew/bin/swiftlint"

# This is the main script to run SwiftLint on every build
if which swiftlint >/dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
```

## Some words on comments and project structure

There are lots of opinions on commenting, so I thought I'd use this section to add some of mine:

- Even if the code is easy to read and "self-explanatory", it should still have "summary comments", to give a quick overview of what a block of code does
- If there was a choice between multiple solution, it's a good idea to add "context comments", to explain why one solution was chosen over the other(s)
- If there are any points where the code does something unexpected or weird, e.g. as a workaround for a bug in some framework, there should be a comment explaining it, ideally also containing a link to where the bug is being tracked

**Documentation comments**, while being designed for people who use your code, can still be very helpful over time and especially in larger projects. Being able to quickly get an overview of a function instead of having to look into the file its in is quite helpful. They should contain a short explanation of what the code is used for and any assumptions that might be made.

**Project structure**, after this point in time the project is structured as follows

- In the `Activities` group Views are split by what they do in the app, it has groups for `Home`, `Projects` and  `Awards`, all containing the files that make up their respective sections in the app. Additionally the `Activities` group contains `ContentView.swift`
  - The `Awards` group also contains the model and data, this is intentional, so adding new awards/features and fixing bugs can be done without jumping between different parts of the project. 
- The `Extensions` group contains all extensions and a `CoreData` subgroup for the Core Data model and extensions
- For now `DataController.swift` does not have a group and instead sits at the top level next to `OddTrackerApp.swift`
- `Localization` and `Configuration` contain their respective files
- Later on there will be a group for `DataControllers` (since the original DataController will be extended and also split up into different files) and one for `ViewModels`