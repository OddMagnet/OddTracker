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