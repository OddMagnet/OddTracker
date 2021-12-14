//
//  ProjectHeaderView.swift
//  OddTracker
//
//  Created by Michael Brünen on 25.11.20.
//

import SwiftUI

/// A View that shows a header for a Project
struct ProjectHeaderView: View {
    @ObservedObject var project: Project

    // initializer only for readability when using this View
    init(for project: Project) {
        _project = ObservedObject(wrappedValue: project)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(project.projectTitle)

                ProgressView(value: project.completionAmount)
                    .accentColor(project.projectColor)
            }

            Spacer()

            NavigationLink(destination: EditProjectView(project: project)) {
                Image(systemName: "square.and.pencil")
                    .accessibilityLabel("Edit Project")
                    .imageScale(.large)
            }
        }
        .padding(.bottom, 10)
        .accessibilityElement(children: .combine)
    }
}

struct ProjectHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProjectHeaderView(for: Project.example)
        }
    }
}
