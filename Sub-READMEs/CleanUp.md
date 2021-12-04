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

