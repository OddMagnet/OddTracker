//
//  HomeView.swift
//  OddTracker
//
//  Created by Michael Brünen on 16.11.20.
//

import SwiftUI
import CoreData

struct HomeView: View {
    // Tag for the TabView in `ContentView.swift`
    static let tag: String? = "Home"
    
    @EnvironmentObject var dataController: DataController

    @FetchRequest(entity: Project.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Project.title, ascending: true)],
                  predicate: NSPredicate(format: "isClosed = false")
    ) var projects: FetchedResults<Project>
    let items: FetchRequest<Item>

    var projectRows: [GridItem] {
        [GridItem(.fixed(100))]
    }

    init() {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted = false")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Item.priority, ascending: false)
        ]
        request.fetchLimit = 10
        items = FetchRequest(fetchRequest: request)
    }

    var body: some View {
        NavigationView {
            Group {
                if projects.count == 0 {
                    Text("There's nothing to see here right now.")
                        .foregroundColor(.secondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHGrid(rows: projectRows) {
                                    ForEach(projects) { project in
                                        VStack(alignment: .leading) {
                                            Text("\(project.projectItems.count) items")
                                                .font(.caption)
                                                .foregroundColor(.secondary)

                                            Text(project.projectTitle)
                                                .font(.title2)

                                            ProgressView(value: project.completionAmount)
                                                .accentColor(project.projectColor)
                                        }
                                        .padding()
                                        .background(Color.secondarySystemGroupedBackground)
                                        .cornerRadius(10)
                                        .shadow(color: Color.black.opacity(0.2), radius: 5)
                                        .accessibilityElement(children: .ignore)
                                        .accessibilityLabel("\(project.projectTitle), \(project.projectItems.count) items, \(project.completionAmount * 100, specifier: "%g")% complete")
                                    }
                                }
                                .padding([.horizontal, .top])
                                .fixedSize(horizontal: false, vertical: true)
                            }

                            VStack(alignment: .leading) {
                                list("Up next", for: items.wrappedValue.prefix(3))
                                list("More to explore", for: items.wrappedValue.dropFirst(3))
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .background(Color.systemGroupedBackground.ignoresSafeArea())
            .navigationTitle("Home")
        }
    }

    @ViewBuilder func list(_ title: LocalizedStringKey, for items: FetchedResults<Item>.SubSequence) -> some View {
        if items.isEmpty {
            EmptyView()
        } else {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top)

            ForEach(items) { item in
                NavigationLink(destination: EditItemView(item: item)) {
                    HStack(spacing: 20) {
                        Circle()
                            .stroke(item.project?.projectColor ?? Color("Light Blue"), lineWidth: 3)
                            .frame(width: 44, height: 44)

                        VStack(alignment: .leading) {
                            Text(item.itemTitle)
                                .font(.title2)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if item.itemDetail.isEmpty == false {
                                Text(item.itemDetail)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.secondarySystemGroupedBackground)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.2), radius: 5)
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
