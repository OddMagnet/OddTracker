//
//  EditProjectView.swift
//  OddTracker
//
//  Created by Michael Brünen on 26.11.20.
//

import SwiftUI

struct EditProjectView: View {
    let project: Project
    let colorColumns = [
        GridItem(.adaptive(minimum: 44))
    ]

    @EnvironmentObject var dataController: DataController

    @State private var title: String
    @State private var detail: String
    @State private var color: String

    init(project: Project) {
        self.project = project

        _title = State(wrappedValue: project.projectTitle)
        _detail = State(wrappedValue: project.projectDetail)
        _color = State(wrappedValue: project.projectColorString)
    }

    var body: some View {
        Form {
            Section(header: Text("Basic Settings")) {
                TextField("Project name", text: $title.onChange(update))
                TextField("Description of this project", text: $title.onChange(update))
            }

            
        }
        .navigationTitle("Edit Project")
    }

    func update() {

    }
}

struct EditProjectView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EditProjectView(project: Project.example)
        }
    }
}
