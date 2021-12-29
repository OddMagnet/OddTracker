//
//  SharedProjectsView.swift
//  OddTracker
//
//  Created by Michael Brünen on 29.12.21.
//

import SwiftUI
import CloudKit

struct SharedProjectsView: View {
    static let tag: String? = "Community"

    @State private var projects = [SharedProject]()
    @State private var loadState = LoadState.inactive

    var body: some View {
        NavigationView {
            Group {
                switch loadState {
                    case .inactive, .loading:
                        ProgressView()
                    case .noResults:
                        Text("No Results")
                    case .success:
                        List(projects) { project in
                            NavigationLink(destination: Color.blue) {
                                VStack(alignment: .leading) {
                                    Text(project.title)
                                        .font(.headline)
                                    Text(project.owner)
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Shared Projects")
        }
        .onAppear(perform: fetchSharedProjects)
    }

    func fetchSharedProjects() {
        // ensure this function is only run from an inactive loading state
        // this avoids constant calls when tabbing through the app
        guard loadState == .inactive else { return }
        loadState = .loading

        // create the query
        let predicate = NSPredicate(value: true)    // it's not possible to omit the predicate, so this just gets everything
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        let query = CKQuery(recordType: "Project", predicate: predicate)
        query.sortDescriptors = [sortDescriptor]

        // create the `CKQueryOperation`
        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = ["title", "detail", "owner", "isClosed"]
        operation.resultsLimit = 50

        // this is called for every record downloaded by CloudKit, based on the above query
        // it converts the data from a `CKRecord` to `SharedProject`
        // additionally the loadstate is set to true, since at least one record already arrived
        operation.recordFetchedBlock = { record in
            let id = record.recordID.recordName
            let title = record["title"] as? String ?? "No title"
            let detail = record["detail"] as? String ?? ""
            let owner = record["owner"] as? String ?? "No owner"
            let isClosed = record["isClosed"] as? Bool ?? false

            let sharedProject = SharedProject(id: id, title: title, detail: detail, owner: owner, isClosed: isClosed)
            projects.append(sharedProject)
            loadState = .success
        }

        // this is called when all records have been retrieved, it gives two values
        // 'cursor', which can be used to fetch more results, should there be any
        // and 'error', if there were any errors
        // they're both optional, for now they're not needed here, since this just checks
        // if there are projects and sets the loadState to `.noRecords` if there are none
        operation.queryCompletionBlock = { _, _ in
            if projects.isEmpty {
                loadState = .noResults
            }
        }

        // send off the operation
        CKContainer.default().publicCloudDatabase.add(operation)
    }
}

struct SharedProjectsView_Previews: PreviewProvider {
    static var previews: some View {
        SharedProjectsView()
    }
}
