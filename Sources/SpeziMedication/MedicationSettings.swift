//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2022 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziViews
import SwiftUI


/// Present medication settings includings mechanisms to add, edit, and delete medications.
public struct MedicationSettings<MI: MedicationInstance>: View {
    private let isPresented: Binding<Bool>?
    private let allowEmtpySave: Bool
    private let medicationSettingsViewModel: any MedicationSettingsViewModel<MI>
    private let action: () -> Void
        
    @State private var cancelAlert = false
    @State private var showAddMedicationSheet = false
    @State private var viewState: ViewState = .idle
    private var viewModel: InternalMedicationSettingsViewModel<MI>
    
    
    private var modifiedMedications: Bool {
        medicationSettingsViewModel.medicationInstances != viewModel.medicationInstances
    }
    
    private var medicationOptions: Set<MI.InstanceType> {
        medicationOptions(medicationSettingsViewModel)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if viewModel.medicationInstances.isEmpty {
                Spacer()
                Text("NO_MEDICATION_DESCRIPTION", bundle: .module)
                    .multilineTextAlignment(.center)
                    .font(.title3)
                    .padding(.horizontal)
                Spacer()
            } else {
                MedicationList<MI>()
            }
            saveMedicationButton
        }
            .background {
                Color(uiColor: .systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
            }
            .navigationTitle(String(localized: "MEDICATION_SETTINGS", bundle: .module))
            .sheet(isPresented: $showAddMedicationSheet) {
                addMedicationView
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    addMedicationButton
                        .disabled(viewState == .processing)
                }
                if let isPresented {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "CANCEL", bundle: .module)) {
                            if !modifiedMedications {
                                isPresented.wrappedValue = false
                            } else {
                                cancelAlert = true
                            }
                        }
                    }
                }
            }
            .viewStateAlert(state: $viewState)
            .alert(isPresented: $cancelAlert) {
                Alert(
                    title: Text("MEDICATION_SETTINGS_CANCEL_ALERT_TITLE", bundle: .module),
                    message: Text("MEDICATION_SETTINGS_CANCEL_ALERT_MESSAGE", bundle: .module),
                    primaryButton: .default(
                        Text("MEDICATION_SETTINGS_CANCEL_ALERT_CANCEL", bundle: .module),
                        action: {
                            cancelAlert = false
                        }
                    ),
                    secondaryButton: .destructive(
                        Text("MEDICATION_SETTINGS_CANCEL_ALERT_DELETE", bundle: .module),
                        action: discardChangesAction
                    )
                )
            }
            .interactiveDismissDisabled(isPresented == nil || modifiedMedications)
            .environment(viewModel)
    }
    
    @MainActor private var saveMedicationButton: some View {
        let title: String
        if viewModel.medicationInstances.isEmpty, !modifiedMedications && allowEmtpySave {
            title = String(localized: "SAVE_NO_MEDICATIONS_BUTTON", bundle: .module)
        } else {
            title = String(localized: "SAVE_MEDICATIONS_BUTTON", bundle: .module)
        }
        
        return AsyncButton(
            action: {
                do {
                    viewState = .processing
                    try await medicationSettingsViewModel.persist(medicationInstances: viewModel.medicationInstances)
                    viewModel.medicationInstances = medicationSettingsViewModel.medicationInstances
                    action()
                    isPresented?.wrappedValue = false
                    viewState = .idle
                } catch let error as LocalizedError {
                    viewState = .error(error)
                } catch {
                    viewState = .error(error.localizedDescription)
                }
            },
            label: {
                Text(title)
                    .frame(maxWidth: .infinity, minHeight: 38)
            }
        )
            .buttonStyle(.borderedProminent)
            .disabled(!modifiedMedications && !allowEmtpySave)
            .padding()
            .background {
                Color(uiColor: .systemGroupedBackground)
                    .edgesIgnoringSafeArea([.horizontal, .bottom])
            }
    }
    
    private var addMedicationButton: some View {
        Button {
            showAddMedicationSheet.toggle()
        } label: {
            Image(systemName: "plus")
                .accessibilityLabel(String(localized: "ADD_NEW_MEDICATION_BUTTON", bundle: .module))
        }
    }
    
    private var addMedicationView: some View {
        AddMedication<MI>(isPresented: $showAddMedicationSheet)
    }
    
    
    /// Initializes a new ``MedicationSettings`` view.
    /// - Parameters:
    ///   - isPresented: An optional binding to allow the ``MedicationSettings`` view to control the presentation of itself, should be used in combination with e.g. a `.sheet(isPresented:)` modifier.
    ///   - allowEmtpySave: Flag to determine if saving without any medication instances is allowed.
    ///   - medicationSettingsViewModel: The ``MedicationSettingsViewModel`` to manage the medication settings.
    ///   - action: An optional closure to be executed after persisting medications and performing custom logic.
    public init( // swiftlint:disable:this function_default_parameter_at_end
        // We disable the default parameter order here to ensure that the action can be a trailing closure but only needs to be optionally provided.
        isPresented: Binding<Bool>? = nil,
        allowEmtpySave: Bool = false,
        medicationSettingsViewModel: any MedicationSettingsViewModel<MI>,
        action: @escaping () -> Void = {}
    ) {
        self.isPresented = isPresented
        self.allowEmtpySave = allowEmtpySave
        self.medicationSettingsViewModel = medicationSettingsViewModel
        self.action = action
        self.viewModel = medicationSettingsViewModel.internalViewModel
    }
    
    
    private func discardChangesAction() {
        viewModel.medicationInstances = medicationSettingsViewModel.medicationInstances
        isPresented?.wrappedValue = false
    }
    
    private func medicationOptions(_ viewModel: some MedicationSettingsViewModel<MI>) -> Set<MI.InstanceType> {
        viewModel.medicationOptions
    }
    
    private func createMedicationInstance(_ viewModel: some MedicationSettingsViewModel<MI>) -> (MI.InstanceType, MI.InstanceDosage) -> MI {
        viewModel.createMedicationInstance(withType:dosage:)
    }
}
