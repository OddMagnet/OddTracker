//
//  ItemListView.swift
//  OddTracker
//
//  Created by Michael Brünen on 07.12.20.
//

import SwiftUI

/// A View that shows a list of Items
struct ItemListView: View {
    let title: LocalizedStringKey
    @Binding var items: ArraySlice<Item>

    var body: some View {
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

struct ItemListView_Previews: PreviewProvider {
    static var dataController = DataController.preview
    static let items: [Item] = [.example, .example, .example]

    static var previews: some View {
        NavigationView {
            VStack(alignment: .leading) {
                ItemListView(
                    title: "Preview",
                    items: Binding.constant(items.prefix(3))
                )
            }
            .padding(.horizontal)
        }
    }
}
