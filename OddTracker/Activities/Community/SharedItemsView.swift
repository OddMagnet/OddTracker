//
//  SharedItemsView.swift
//  OddTracker
//
//  Created by Michael Brünen on 29.12.21.
//

import SwiftUI
import CloudKit

struct SharedItemsView: View {
    let project: SharedProject

    // items
    @State private var items = [SharedItem]()
    @State private var itemsLoadState = LoadState.inactive
    // messages
    @State private var messages = [ChatMesssage]()
    @AppStorage("username") var username: String?
    @State private var showingSignIn = false
    @State private var newChatText = ""

    var body: some View {
        List {
            Section {
                switch itemsLoadState {
                    case .inactive, .loading:
                        ProgressView()
                    case .noResults:
                        Text("No results")
                    case .success:
                        ForEach(items) { item in
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .font(.headline)

                                if item.detail.isEmpty == false {
                                    Text(item.detail)
                                }
                            }
                        }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(project.title)
        .onAppear(perform: fetchSharedItems)
        .sheet(isPresented: $showingSignIn, content: SignInView.init)
    }

    func fetchSharedItems() {
        // ensure this function is only run from an inactive loading state
        // this avoids constant calls when tabbing through the app
        guard itemsLoadState == .inactive else { return }
        itemsLoadState = .loading

        // create the query
        let recordID = CKRecord.ID(recordName: project.id)
        let reference = CKRecord.Reference(recordID: recordID, action: .none)
        let predicate = NSPredicate(format: "project == %@", reference)
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        let query = CKQuery(recordType: "Item", predicate: predicate)
        query.sortDescriptors = [sortDescriptor]

        // create the `CKQueryOperation`
        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = ["title", "detail", "isCompleted"]
        operation.resultsLimit = 50

        // this is called for every record downloaded by CloudKit, based on the above query
        // it converts the data from a `CKRecord` to `SharedItem`
        // additionally the loadstate is set to true, since at least one record already arrived
        operation.recordFetchedBlock = { record in
            let id = record.recordID.recordName
            let title = record["title"] as? String ?? "No title"
            let detail = record["detail"] as? String ?? ""
            let isCompleted = record["isCompleted"] as? Bool ?? false

            let sharedItem = SharedItem(id: id, title: title, detail: detail, isCompleted: isCompleted)
            items.append(sharedItem)
            itemsLoadState = .success
        }

        // this is called when all records have been retrieved, it gives two values
        // 'cursor', which can be used to fetch more results, should there be any
        // and 'error', if there were any errors
        // they're both optional, for now they're not needed here, since this just checks
        // if there are items and sets the loadState to `.noRecords` if there are none
        operation.queryCompletionBlock = { _, _ in
            if items.isEmpty {
                itemsLoadState = .noResults
            }
        }

        // send off the operation
        CKContainer.default().publicCloudDatabase.add(operation)
    }

    func signIn() {
        showingSignIn = true
    }

    func sendChatMessage() {
        // ensure there is a message and username
        let text = newChatText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count > 2 else { return }
        guard let username = username else { return }

        // create a record with the username and text
        let message = CKRecord(recordType: "Message")
        message["from"] = username
        message["text"] = text

        // add a reference to the project
        let projectID = CKRecord.ID(recordName: project.id)
        message["project"] = CKRecord.Reference(recordID: projectID, action: .deleteSelf)

        // backup text in case of error. clear it so the UI instantly updates
        let backupChatText = newChatText
        newChatText = ""

        // send off the new record
        CKContainer.default().publicCloudDatabase.save(message) { record, error in
            // check for errors, if there was one reset the message box
            if let error = error {
                print(error.localizedDescription)
                newChatText = backupChatText
            // otherwise create the record locally and add it to the list, so the UI updates immediately
            } else if let record = record {
                let message = ChatMesssage(from: record)
                messages.append(message)
            }
        }
    }
}

struct SharedItemsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SharedItemsView(project: .example)
        }
    }
}
