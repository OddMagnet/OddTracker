# Internationalization and Localization

First up is the internationalization, one of the most useful settings for this is the "Show non-localized strings" setting `(⌥⌘R -> Options)`, with it enabled non-localzed strings are shown in uppercase letters, making it easy to identify them.

The process of localizing itself is rather easy since lots of views and modifiers that display text support `LocalizedStringKey`, which means that SwiftUI will attempt to look their strings up in the localization table.

Localizing then is as simple as adding a "Strings File", named `Localizable.strings`, and adding text in the format of `"KeyString" = "ValueString";`, where `KeyString` is the text that is being localized and the `ValueString` is the localized value, terminated by a semicolon.

It's also possible to use comments in the localization files, which is helpful to create sections and describe the context in which the strings appear, making it easier to correctly translate them.

Another really helpful tool for localzing is the command line tool `genstrings -SwiftUI *.swift`, using it with the SwiftUI flag and telling it to scan all files that end on `.swift`, it then creates a `Localizable.strings` file, or if it already exists, overwrites it. It isn't perfect, but it accelerates the beginning of the localization by a lot, what was missed can then simply be added by hand.

One last thing that needs to be adressed before translating is interpolated strings. At the top of the generated strings file is the line `"%@ items" = "%@items";`, the `%@` indicates an interpolated string, but for this to work Swift needs to know exactly what kind of data will be interpolated, a 64 bit integer in this case, historically known as 'long long integer', changing the `%@ items` to `%lld items` is all that would be needed here. Would be, because for this app it's handled with the handling of plurals a bit further down.

To test for languages with very long words, the option for "Double-Length Pseudolanguage" `(⌥⌘R -> Options)` comes in handy, however the "Up next" and "More to explore" strings in the `HomeView` remain un-doubled, this is fixed by changing the `String` parameter of the `list()` method to `LocalizedStringKey`. One more thing that doesn't get localized are the default strings 'New Item' and 'New Project' for new items and projects respectively, this can be solved be sending back an `NSLocalizedString` from the extensions for `Item` and `Project`, where they return the default strings.

## Handling plurals

To handle how the system pluralizes words, the `Localizable.stringsdict` file is created, which is an XML file that contains strings that need to be matched and the information on how they should be handled. When viewing it as source code (Open As -> Source Code), reading it in order and making changes as necessary:

- Replacing `StringKey`, the string that exists in the code, with `%lld items`
- `<string>%#@VARIABLE@</string>` could be used to look for specific formats inside the string, which is currently not needed, so it remains unchanged
- `<key>VARIABLE</key>` could be used to tell iOS how to handle the variable defined above, this also remains unchanged
- Below `NSSTringFormatValueTypeKey` is an empty string, which tells Swift what kind of value should be checked, in this case `lld`
- The rest of the lines contains rules for various numeric situations, the key describing the situation, e.g. `<key>zero</key>` followed by the string that should be used for that situation, e.g. `<string>Empty</empty>`
- Situations that aren't used in a language, e.g. 'two', 'few', and 'many' in english can simply be deleted.

While a bit of an overkill for just one language, stringsdict files are extremely powerful for multiple and more complext string formats.

## Adding another language

Since everything is in place for internationalization and localization, adding another language is easy. In the project settings, under the 'Info' tab in the localizations section, the '+' button is used to select the language to add. 

With the `Localizable.strings` file selected, in the file inspector, pressing the 'Localize' button and confirming will add the existing `Localizable.strings` file to the initial localization. Still in the file inspector, checking the box for the language added in the first step, Xcode will then copy the existing `Localizable.strings` file and use it as a starting point for the new language and start showing a disclosure indicator next to the `Localizable.strings` file. 

The same process can be repeated for the `Localizable.stringsdict` and the `Awards.json` files as well. When clicking the disclosure indicator, it opens up and shows files for both the initial and the newly added language. The only thing left to do then is to translate and pluralize.