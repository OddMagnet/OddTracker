//
//  EditProjectView.swift
//  OddTracker
//
//  Created by Michael Brünen on 26.11.20.
//

import SwiftUI
import CoreHaptics

/// A View that shows the editing options for a Project
struct EditProjectView: View {
    @ObservedObject var project: Project
    let colorColumns = [
        GridItem(.adaptive(minimum: 44))
    ]

    @EnvironmentObject var dataController: DataController
    @Environment(\.presentationMode) var presentationMode

    @State private var title: String
    @State private var detail: String
    @State private var color: String
    @State private var showingDeleteConfirm = false
    @State private var hapticEngine = try? CHHapticEngine()

    init(project: Project) {
        self.project = project

        // self.value = value is not possible here
        // this is because no property wrappers have been created before
        // so instead a property is wrapped in state by using `State(wrappedValue:)`
        // the `_value = ...` is needed to assign property wrapper itself instead of assigning to the wrapped value
        _title = State(wrappedValue: project.projectTitle)
        _detail = State(wrappedValue: project.projectDetail)
        _color = State(wrappedValue: project.projectColorString)
    }

    var body: some View {
        Form {
            Section(header: Text("Basic Settings")) {
                TextField("Project name", text: $title.onChange(update))
                TextField("Description of this project", text: $detail.onChange(update))
            }

            Section(header: Text("Custom project color")) {
                LazyVGrid(columns: colorColumns) {
                    ForEach(Project.colors, id: \.self, content: colorButton)
                }
                .padding(.vertical)
            }

            Section(footer: Text("Closing a project moves it from the Open to Closed tab; deleting it removes the project completely.")) {
                Button(project.isClosed ? "Reopen this project" : "Close this project", action: toggleClosed)

                Button("Delete this project") {
                    showingDeleteConfirm.toggle()
                }
                .accentColor(.red)
            }
        }
        .navigationTitle("Edit Project")
        .onDisappear(perform: dataController.save)
        .alert(isPresented: $showingDeleteConfirm) {
            Alert(
                title: Text("Delete project?"),
                message: Text("Are you sure you want to delete this project? You will also delete all the items it contains."),
                primaryButton: .default(Text("Delete"), action: delete),
                secondaryButton: .cancel()
            )
        }
    }

    func colorButton(for item: String) -> some View {
        ZStack {
            Color(item)
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(6)

            if item == color {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.white)
                    .font(.largeTitle)
            }
        }
        .onTapGesture {
            color = item
            update()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(
            item == color
                ? [.isButton, .isSelected]
                : .isButton
        )
        .accessibilityHint(LocalizedStringKey(item))
    }

    func toggleClosed() {
        project.isClosed.toggle()
        // on project close, play haptics effect
        if project.isClosed {
            do {
                try hapticEngine?.start()

                // Sharpness defines whether the effect is pronounced or dull, in this case dull
                // while Intensity determines the strength of the vibration
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0)
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)

                // define the parameter curves control points
                // the values for the control points and time are relative to each others
                let start = CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 1)
                let end = CHHapticParameterCurve.ControlPoint(relativeTime: 1, value: 0)

                // then create the curve itself
                let parameterCurve = CHHapticParameterCurve(
                    parameterID: .hapticIntensityControl,
                    controlPoints: [start, end],
                    relativeTime: 0
                )

                // first event, a quick tap, strong and dull
                let event1 = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: 0
                )

                // second event, a buzz, strong and dull as well, lasting for 1 second
                let event2 = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [sharpness, intensity],
                    relativeTime: 0.125,
                    duration: 1
                )

                // create a pattern of events with the parameter curve
                let pattern = try CHHapticPattern(
                    events: [event1, event2],
                    parameterCurves: [parameterCurve]
                )

                // finally, create a player with the pattern, and play the haptics
                let player = try hapticEngine?.makePlayer(with: pattern)
                try player?.start(atTime: 0)
            } catch {

            }
        }
    }

    func update() {
        project.title = title
        project.detail = detail
        project.color = color
    }

    func delete() {
        dataController.delete(project)
        presentationMode.wrappedValue.dismiss()
    }
}

struct EditProjectView_Previews: PreviewProvider {
    static var dataController = DataController.preview

    static var previews: some View {
        NavigationView {
            EditProjectView(project: Project.example)
                .environmentObject(dataController)
        }
    }
}
