# Cleanup

At this point all of the basics are working, now comes accessibility, documentation, project structure and more.

## Accessibility

First comes Voice Over, by default Voice Over makes the app more accessible, but there are still things that can be done better. Grouping elements into one with the `.accessibilityElement()` modifier for example makes the home view much easier to navigate with Voice Over, setting before mentioned modifier to ignore children and combining it with the `.accessibilityLabel()` modifier to provide a custom label makes it even better. In the projects view the `.accessibilityElement()` modifier is also used to combine the `HStack` in the `ProjectHeaderView`

For basic controls Voice Over works just fine, for some custom controls, like the colors displayed in the `EditProjectView`, it does not, those are unavailable without adding some modifiers. Hiding the Stack with `.accessibilityElement()`, followed by adding some traits with the `.accessibilityAddTraits()` and localizing the color names with an `.accessibilityLabel()` does the trick.

Finally, to fix some small labeling problems the award buttons in `AwardsView` get a `.accessibilityLabel()` that even tells the user that the award is unlocked and its name, or that its locked. Additionally the awards description is given. `ItemRowView` gets a computed property `label` which is used in the `.accessibilityLabel()` for the `NavigationLink()` views, so every item will have a fitting description. 

## Cleaning up view code 

coming soon...