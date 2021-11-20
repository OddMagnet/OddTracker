# Filling Functionality

## Adding and deleting

So far the app has functionality to edit items and projects and also delete projects, but not adding them in the first place. 

To add new projects the `.toolbar()` modifier is used to add a `Button` view, which creates a new, open project and saves it right away. This button only shows when viewing open projects.

The functionality to add items is attached directly to each project, as a static row containing a buttonw view, after the `ForEach` view in `ProjectsView` that lists all the items in a project. It creates a new items and saves it right away.

To delete items the `.onDelete()` modifier is used, with a closure that accepts the offsets of items that will be deleted, goes over the offsets and deletes every item, then saves the changes.

SwiftUI also offers a dedicated `.remove(atOffsets:)` modier, but since it is necessary to know both which item index and which projects index to delete from the Core Data context, the above modifier won't work. 

The `.onDelete()` approach works for two reasons:

- it gets passed an `IndexSet` (a special collection type that is sorted and only contains unique integers >=0), so there is no need to worry about index order
- deleting a Core Data object doesn't remove it until `save()` is called on the data controller, which means indexes won't change as each item is deleted

## Custom sorting for items

To enable sorting the items in projects by different criteria, two computed property, `projectItemsDefaultSorted` and `projectItems(using:)`, are added. Both return an `[Item]`.

The first one simply returns the items sorted by completion, then priority, then date. For the second an `Enum` is added to the `Item-CoreDateHelpers` extension and a `@State` property to track the sorting order, which is passed to the `projectItems(using:)` function.

Other possible solution for sorting would've been key paths, which would take a lot of working around for little gain and `NSSortDescriptor`, which would've required the actual core data attributes instead of the non-optional wrappers.

To change the sorting a `Button` is added to the `ProjectsView`, that toggles an actionsheet.

## Finishing ProjectsView

The rows for items in `ProjectsView` so far only showed the name of the item, to change that the text was changed to a `Label` view, tinted in the projects color, containing the items name and an icon to indicate status, either a checkmark, filled when the item is completed, clear when not, or a triangle with exclamation mark for high priority items.

Additionally the views needed for a working landscape mode on bigger deviced were added. The app will now show some text when there are no items and show the text in the secondary view, telling the user to select a project from the primary view.

## Reading awards JSON

To encourage users to continue completing items and projects, a JSON file containing data for some awards, as well as a corrosponding `Award` struct was added. This file is loaded via an extension on `Bundle`, the `decode(...)` method in it

- locates a specific filename in the particular bundle
- attempts to load said file into a `Data` instance
- converts said instance to a Swift object of a given type (that conforms to `Decodable`) and returns it
- and throws detailed errors if necessary

Additionally the method accepts a date decoding strategy, defaulting to `.deferredToDate` (the default for `Codable`, so it can be omitted) as well as a key decoding strategy,  defaulting to `.useDefaultKeys` (also the default for `Codable`).

The method can throw errors when:

- the file is missing from the bundle
- the content of the file can't be loaded into a `Data`
- when keys are missing for the decoding
- when the type doesn't match
- when the type value is missing
- when the JSON is invaliud
- when the decoding fails for some other reason

All of them are using `fatalError()`, since none of those issues should happen with a file included in the app.

The `Awards` struct conforms to identifiable and has an `id` (using the objects unique name) for easier use with SwiftUI. Additionally it has a static `allAwards` property that loads from the `Awards.json` file, using the previously mentioned extension, and astatic `example` property for preview and testing purposes.

Finally an `AwardsView` was added as a tab in the tab bar, to show the user which awards have been earned so far and which not, using a `LazyVGrid` view.

## Counting Core Data results

A simple way to count with core data is to ask the view context for the count of a fetch request, this is quite fast since Core Data doesn't actually need to retrieve all the attributes for every object it stores.

This is useful for the `hasEarned(award:)` function, which evaluates is a user has earned a certain award. Based on the criterion of the award it creates a fetch requests, gets the count for said requests and returns either true if the criterion is fullfilled, false otherwise.

With the use of the `hasEarned(award:)` function (via the data controller) it is now possible to color the awards in the `AwardsView` with the `.foregroundColor()` modifier and a simply ternary check.

Additionally, when tapping an award, the user is shown an alert, either congratulating the user on unlocking the award, or telling them what they need to do to unlock it. 

Usually showing the alert on the change of a single optional, identifiable, property would be good enough, but in this case there are two properties, `selectedAward`, which contains the awards the user tapped and `showingAwardDetails`, a boolean which triggers the alert. This approach was used for future functions that need the selected awards after the alert is dismissed. An optional identifiable property would've been reset to nil after the award was dismissed.

Showing the alert itself is trivial, the awards are all buttons, so they can set the `selectedAward` property and toggle `showingAwardDetails`, the only thing left then is the `.alert(isPresented:)` modifier, which checks if the award has been earned and then presents the corrosponding message.

## Creating the Home View

Instead of using a simple view from SwiftUI, the `HomeView` gets a bit more custom. 

A small extension `Colour-Additions` wrapping UIKit's values for `.systemGroupedBackground` and `.secondarySystemGroupedBackground`, which have the bonus of being dark mode aware. 

Multiple fetch requests, to show open projects with their completion amounts as well as 10 items that are incomplete and have high priority. The second requests is a custom one, so instead of getting all matching rows and then only using 10, the fetch requests will only get 10 rows. 

For this, the `HomeView` gets a new `items` property, to store the custom fetch request and an initialiser where it is created. The fetch requests gets created as usual, assigned a predicate and sort descriptors and in addition to that a `.fetchLimit` to accomplish the goal of only fetching 10 items. 

It's noteworthy that this doesn't actually increase performance, since Core Data still needs to read all rows so it can sort. Without the sort descriptors it would be a performance enhancement though.

The projects themselves are displayed in a simple `LazyHGrid` at the top of the `HomeView`, using the secondary background color mentioned earlier and the `.fixedSize()` modifier, since SwiftUI got the dividing of space between grid and lists below pretty wrong without it.

The 10 high priority items are listed below in two sections, "Up next" and "More to explore". For this a method that just returns a slice of the fetched results, which are then given to a method with the `@ViewBuilder` attribute, so whatever calls the method can position them. Finally, each item returned will be a navigation link to an `EditItemView`, so the users can get right to editing them if they feel like it.
