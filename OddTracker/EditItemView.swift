//
//  EditItemView.swift
//  OddTracker
//
//  Created by Michael Brünen on 23.11.20.
//

import SwiftUI

struct EditItemView: View {
    let item: Item
    @EnvironmentObject var dataController: DataController

    @State private var title: String
    @State private var detail: String
    @State private var priority: Int
    @State private var completed: Bool

    init(item: Item) {
        self.item = item

        _title = State(wrappedValue: item.itemTitle)
        _detail = State(wrappedValue: item.itemDetail)
        _priority = State(wrappedValue: Int(item.priority))
        _completed = State(wrappedValue: item.isCompleted)
    }

    var body: some View {
        Form {
            Section(header: Text("Basic Settings")) {
                TextField("Item name", text: $title)
                TextField("Description", text: $detail)
            }

            Section(header: Text("Priority")) {
                Picker("Priority", selection: $priority) {
                    Text("Low").tag(1)
                    Text("Medium").tag(2)
                    Text("High").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
            }

            Section {
                Toggle("Mark completed", isOn: $completed)
            }
        }
        .navigationTitle("Edit Item")
        .onDisappear(perform: update)
    }

    func update() {
        item.title = title
        item.detail = detail
        item.priority = Int16(priority)
        item.isCompleted = completed

        // ensure SwiftUI is aware of the change in state
        item.project?.objectWillChange.send()
    }
}

struct EditItemView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EditItemView(item: Item.example)
                .preferredColorScheme(.dark)
        }
    }
}
