# Testing

Note that all that is written here is based on the state of the app when this was written. Tests added in the future won't be mentioned here.

## Basics

### Code Coverage

- Code Coverage can show which parts of the code are covered by tests
  - Code coverage collection can be enabled in the menu that can be accessed via **⌥⌘U**
  - To see which code is covered, the option for Code Coverage in the Editor menu must be enabled
- **Note**: just because code is showing as "covered", does not mean it's **fully** tested

### Testing bundled data

Something that stuck with me when I first learned about test writing was the sentence: "_A good tester is one who looks both ways before crossing a one-way street_". So to start off the testing, two tests for 'obvious' stuff are added, `testColorsExist()` to ensure all the colors in the static `colors` array are available and `testJSONLoadsCorrectly()` to ensure the awards from `Awards.json` are loaded and valid.

## Core Data

For Core Data the following initial tests were added;

- In `ProjectTests`

  - `testCreatingProjectAndItems()` tests the creation of a fixed amount of projects and items belonging to those projects

  - `testDeletingProjectCascadeDeletesItems()` tests that the deletion of a project also deletes all of its items

- In `AwardTests`

  - `testAwardIDMatchesName()` tests that the awards id matches its name
  - `testNewUserHasNoAwards()` tests that a new user has no awards
  - `testAddingItems()` tests that the corresponding awards for adding a certain amount of items are earned
  - `testCompletedAwards()` tests that the corresponding awards for completing a certain amount of items are earned

## Development Data

Even non-public parts (e.g. parts of the code only used for development of the app itself) need to be testes.

- In `DevelopmentTests`
  - `testSampleDataCreationWorks()` tests that the sample data is created and as expected
  - `testDeleteAllClearsEverything()` tests that the `deleteAll()` function works as intended 
  - `testExampleProjectIsClosed()` tests that the example project is closed
  - `testExampleItemIsHighPriority()` tests that the example item is high priority

An interesting side-note: When writing the tests a problem appeared. Internally `DataController` creates an `NSPersistentCloudKitContainer` for the Core Data work. Both the `BaseTestCase` as well as the main app create their own instance of `DataController`, which means `NSPersistentCloudKitContainer` starts up twice, tries to find the model file, loads the entities from it and then gets 'confused' since there are now two `Item` entities, both claiming they should own the `Item` class.

To fix this problem a new static `model` property is added to `DataController`, which is used to load the model, only loading it once, and returns an `NSManagedObjectModel` instance. This is then used in `DataControllers` initializer, with the longer `NSPersistentCloudKitContainer(name:managedObjectModel:)` initializer.

## Extensions

The project has a couple of extensions that add functionality to Apple's own code, since that code can potentially change in the future, the extensions need to be tested to ensure they keep working as intended.

- In `ExtensionTests`
  - `testSequenceKeyPathSortingSelf()` tests that the `\.self` keypath sorting works correctly
  - `testSequenceKeyPathSortingCustom()` tests that sorting with a custom comparator function works correctly
  - `testBundleDecodingAwards()` tests that the decoding of the `awards.json` file works correctly
  - `testDecodingString()` and `testDecodingDictionary()` both test the `decode()` function in the extension on `Bundle`, to ensure it works correctly
  - `testBindingOnChangeCallsFunction()` tests the `onChange()` function in the extension on `Binding`, to ensure it works correctly

The tests for decoding both use so called "test fixtures", files specifically created for testing that contain predetermined content, instead of testing with files belonging to the main app.

The `testBindingOnChangeCallsFunction()` tests the `onChange()` function by using a function that captures a boolean variable and changes it to 'true' when it's run. That function is then set to be called in `onChange()` and the binding is changed. The test is successfull when the boolean variable changed to 'true'.

## Performance

For performance testing the following is done in `PerformanceTests`:

- Creating a huge amount of sample data (x100)
- Creating a huge amount of awards (x25)
- Then measure how fast the app can check which awards are earned

At the time of writing this tests for 500 projects with 25x the amount of awards.

## UI

