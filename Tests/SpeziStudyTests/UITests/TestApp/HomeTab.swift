//
// This source file is part of the Stanford Spezi open-source project
//
// SPDX-FileCopyrightText: 2025 Stanford University and the project authors (see CONTRIBUTORS.md)
//
// SPDX-License-Identifier: MIT
//

import SpeziScheduler
import SpeziSchedulerUI
import SpeziStudy
import SpeziViews
import SwiftUI


struct HomeTab: View {
    @Environment(StudyManager.self)
    private var studyManager
    
    @StudyManagerQuery(StudyEnrollment.self)
    private var enrollments
    
    @EventQuery(in: Date.today..<Date.nextWeek)
    private var events
    
    @State private var viewState: ViewState = .idle
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    actions
                }
                Section {
                    ForEach(enrollments) { enrollment in
                        makeStudyEnrollmentRow(for: enrollment)
                    }
                }
                if events.isEmpty {
                    ContentUnavailableView("No Events", systemImage: "calendar")
                } else {
                    ForEach(events) { event in
                        Section {
                            InstructionsTile(event) {
                                EventActionButton(event: event) {
                                    `try`(with: $viewState) {
                                        try event.complete()
                                    }
                                }
                            }
                        }
                    }
                    .injectingCustomTaskCategoryAppearances()
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .viewStateAlert(state: $viewState)
        }
    }
    
    @ViewBuilder private var actions: some View {
        let mockStudyV1 = mockStudy(revision: .v1)
        let mockStudyV2 = mockStudy(revision: .v2)
        let mockStudyV3 = mockStudy(revision: .v3)
        AsyncButton("Enroll in \(mockStudyV1.metadata.title) (v\(mockStudyV1.studyRevision))", state: $viewState) {
            try await studyManager.enroll(in: mockStudyV1)
        }
        AsyncButton("Update enrollment to study revision 2", state: $viewState) {
            try await studyManager.informAboutStudies([mockStudyV2])
        }
        .disabled(!enrollments.contains { $0.studyId == mockStudyV1.id && $0.studyRevision < mockStudyV2.studyRevision })
        AsyncButton("Update enrollment to study revision 3", state: $viewState) {
            try await studyManager.informAboutStudies([mockStudyV3])
        }
        .disabled(!enrollments.contains { $0.studyId == mockStudyV1.id && $0.studyRevision < mockStudyV3.studyRevision })
        AsyncButton("Unenroll from Study", state: $viewState) {
            if let enrollment = enrollments.first {
                try studyManager.unenroll(from: enrollment)
            }
        }.disabled(enrollments.isEmpty)
    }
    
    @ViewBuilder
    private func makeStudyEnrollmentRow(for enrollment: StudyEnrollment) -> some View {
        VStack {
            if let study = enrollment.study {
                HStack {
                    Text(study.metadata.title)
                        .font(.headline)
                }
            }
            HStack {
                Text("Study ID")
                Spacer()
                Text(enrollment.studyId.uuidString)
                    .font(.caption2)
                    .monospaced()
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            HStack {
                Text("Study Revision")
                Spacer()
                Text("\(enrollment.studyRevision)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            HStack {
                Text("Enrollment Date")
                Spacer()
                Text(DateFormatter.localizedString(from: enrollment.enrollmentDate, dateStyle: .short, timeStyle: .none))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }
}


func `try`(with viewState: Binding<ViewState>, action: () throws -> Void) {
    do {
        try action()
    } catch {
        viewState.wrappedValue = .error((error as? any LocalizedError) ?? AnyLocalizedError(error: error))
    }
}
