//
//  ItemRowViewModel.swift
//  OddTracker
//
//  Created by Michael Brünen on 16.03.21.
//

import Foundation

extension ItemRowView {
    class ViewModel: ObservableObject {
        private let project: Project
        private let item: Item

        init(for item: Item, in project: Project) {
            self.project = project
            self.item = item
        }

        var itemTitle: String {
            item.itemTitle
        }

        var icon: String {
            if item.isCompleted {
                return "checkmark.circle"
            } else if item.priority == 3 {
                return "exclamationmark.triangle"
            } else {
                return "checkmark.circle"
            }
        }

        var color: String? {
            if item.isCompleted || item.priority == 3 {
                return project.projectColorString
            } else {
                return nil
            }
        }

        var label: String {
            if item.isCompleted {
                return "\(item.itemTitle), completed"
            } else if item.priority == 3 {
                return "\(item.itemTitle), high priority"
            } else {
                return item.itemTitle
            }
        }
    }
}
