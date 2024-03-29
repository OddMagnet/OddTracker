//
//  EditProjectView.swift
//  OddTracker
//
//  Created by Michael Brünen on 26.11.20.
//

import SwiftUI
import CoreHaptics
import CloudKit

/// A View that shows the editing options for a Project
struct EditProjectView: View {
    enum CloudStatus {
        case checking, exists, absent
    }

    @ObservedObject var project: Project
    let colorColumns = [
        GridItem(.adaptive(minimum: 44))
    ]

    @EnvironmentObject var dataController: DataController
    @Environment(\.presentationMode) var presentationMode

    @AppStorage("username") var username: String?
    @State private var showingSignIn = false
    @State private var cloudStatus = CloudStatus.checking
    @State private var cloudError: CloudError?

    @State private var title: String
    @State private var detail: String
    @State private var color: String
    @State private var remindMe: Bool
    @State private var reminderTime: Date
    @State private var showingDeleteConfirm = false
    @State private var showingNotificationsError = false
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

        // check if the project has a reminder time and set the `remindMe` and `reminderTime` state accordingly
        if let projectReminderTime = project.reminderTime {
            _reminderTime = State(wrappedValue: projectReminderTime)
            _remindMe = State(wrappedValue: true)
        } else {
            _reminderTime = State(wrappedValue: Date())
            _remindMe = State(wrappedValue: false)
        }
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

            Section(header: Text("Project reminders")) {
                Toggle("Show reminders", isOn: $remindMe.animation().onChange(update))

                if remindMe {
                    DatePicker(
                        "Reminder time",
                        selection: $reminderTime.onChange(update),
                        displayedComponents: .hourAndMinute
                    )
                }
            }

            Section(footer: Text("Closing a project moves it from the Open to Closed tab; deleting it removes the project completely.")) {
                Button(project.isClosed ? "Reopen this project" : "Close this project", action: toggleClosed)

                Button("Delete this project") {
                    showingDeleteConfirm.toggle()
                }
                .accentColor(.red)
                .alert(isPresented: $showingDeleteConfirm) {
                    Alert(
                        title: Text("Delete project?"),
                        message: Text("Are you sure you want to delete this project? You will also delete all the items it contains."),
                        primaryButton: .default(Text("Delete"), action: delete),
                        secondaryButton: .cancel()
                    )
                }
            }
        }
        .navigationTitle("Edit Project")
        .toolbar {
            switch cloudStatus {
                case .checking:
                    ProgressView()
                case .exists:
                    Button {
                        removeFromCloud(deleteLocal: false) // only remove from cloud
                    } label: {
                        Label("Remove from iCloud", systemImage: "icloud.slash")
                    }
                case .absent:
                    Button(action: uploadToCloud) {
                        Label("Upload to iCloud", systemImage: "icloud.and.arrow.up")
                    }
            }
        }
        .onDisappear(perform: dataController.save)
        .alert(isPresented: $showingNotificationsError) {
            Alert(
                title: Text("Oops!"),
                message: Text("There was a problem. Please check you have notifications enabled."),
                primaryButton: .default(Text("Check Settings"), action: showAppSettings),
                secondaryButton: .cancel()
            )
        }
        .alert(item: $cloudError) { error in
            Alert(
                title: Text("There was an error!"),
                message: Text(error.localizedMessage)
            )
        }
        .onAppear(perform: updateCloudStatus)
        .sheet(isPresented: $showingSignIn, content: SignInView.init)
    }

    // MARK: - Helper Views
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

    // MARK: - Project changes
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
                // realistically, the haptic engine should not fail, and if it does it doesn't cause any issues
            }
        }
    }

    func update() {
        project.title = title
        project.detail = detail
        project.color = color

        if remindMe {
            project.reminderTime = reminderTime

            dataController.addReminders(for: project) { success in
                // if the adding of the reminder failed, reset the state and show an error
                if success == false {
                    project.reminderTime = nil          // ensure the project does not have an active reminder in place
                    remindMe = false
                    showingNotificationsError = true
                }
            }
        } else {
            project.reminderTime = nil
            dataController.removeReminders(for: project)
        }
    }

    func delete() {
        // if it exists, delete cloud first and also let it delete local as well
        if cloudStatus == .exists {
            removeFromCloud(deleteLocal: true)
        } else {
        // if not, then only delete local data
            dataController.delete(project)
        }
        presentationMode.wrappedValue.dismiss()
    }

    /// Show the settings for the app, useful to help the user (re-)enable notifications etc
    func showAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    // MARK: - iCloud
    func updateCloudStatus() {
        project.checkCloudStatus { exists in
            cloudStatus = exists ? .exists : .absent
        }
    }

    func uploadToCloud() {
        if let username = username {
            let records = project.prepareCloudRecords(owner: username)
            let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
            operation.savePolicy = .allKeys

            operation.modifyRecordsCompletionBlock = { _, _, error in
                if let error = error {
                    cloudError = CloudError(from: error)
                }
                // re-check status upon completion, so the toolbar icon can update
                updateCloudStatus()
            }

            // set to checking before starting the operation
            // on completion the `updateCloudStatus()` function is called to set it again
            cloudStatus = .checking
            CKContainer.default().publicCloudDatabase.add(operation)
        } else {
            showingSignIn = true
        }
    }

    func removeFromCloud(deleteLocal: Bool) {
        let name = project.objectID.uriRepresentation().absoluteString
        let id = CKRecord.ID(recordName: name)

        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [id])

        operation.modifyRecordsCompletionBlock = { _, _, error in
            if let error = error {
                cloudError = CloudError(from: error)
            } else {
                if deleteLocal {
                    dataController.delete(project)
                    presentationMode.wrappedValue.dismiss()
                }
            }

            // re-check status upon completion, so the toolbar icon can update
            updateCloudStatus()
        }

        // set to checking before starting the operation
        // on completion the `updateCloudStatus()` function is called to set it again
        cloudStatus = .checking
        CKContainer.default().publicCloudDatabase.add(operation)
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
