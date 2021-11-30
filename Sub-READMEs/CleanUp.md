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

## Cleaning up Core Data

Coming soon ...