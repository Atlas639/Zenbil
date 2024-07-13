//
//  SessionScrollView.swift
//  Zenbil
//
//  Created by Berhan Witte on 10.07.24.
//

import SwiftUI

struct SessionScrollView: View {
    @Binding var sessions: [SessionData]
    @Binding var selectedSessions: Set<UUID>
    @Binding var activeSession: UUID?
    @Binding var activeItem: UUID?
    @Binding var isSelectionMode: Bool
    @Binding var expandedSession: UUID?
    @Binding var thumbnails: [UUID: CGImage]
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(sessions, id: \.id) { session in
                    SessionView(
                        session: session,
                        sessions: $sessions,
                        isSelectionMode: $isSelectionMode,
                        activeItem: $activeItem,
                        isSelected: selectedSessions.contains(session.id),
                        isActive: activeSession == session.id,
                        isExpanded: expandedSession == session.id,
                        thumbnails: $thumbnails,
                        onTap: {
                            print("Session tapped: \(session.id)")
                            handleSessionTap(session)
                        },
                        onLongPress: {
                            print("Session long pressed: \(session.id)")
                            withAnimation {
                                isSelectionMode = true
                                print("Selection mode enabled")
                            }
                            let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedbackgenerator.impactOccurred()
                        }
                    )
                }
                PlusButton(action: addSession, isSelectionMode: isSelectionMode)
            }
            .padding()
        }
    }
    
    private func handleSessionTap(_ session: SessionData) {
        print("Handling session tap: \(session.id)")
        if isSelectionMode {
            manageSessionSelection(session)
        } else {
            handleActiveSession(session)
        }
    }
    
    private func manageSessionSelection(_ session: SessionData) {
        print("Managing session selection: \(session.id)")
        if selectedSessions.contains(session.id) {
            selectedSessions.remove(session.id)
            print("Session deselected: \(session.id)")
        } else {
            selectedSessions.insert(session.id)
            print("Session selected: \(session.id)")
        }
    }
    
    private func handleActiveSession(_ session: SessionData) {
        print("Handling active session: \(session.id)")
        if activeSession == session.id {
            toggleExpandedSession(session)
        } else {
            setActiveSession(session)
        }
    }
    
    private func toggleExpandedSession(_ session: SessionData) {
        withAnimation {
            expandedSession = expandedSession == session.id ? nil : session.id
            print("Toggled expanded session: \(session.id), expandedSession: \(String(describing: expandedSession))")
        }
    }
    
    private func setActiveSession(_ session: SessionData) {
        activeSession = session.id
        expandedSession = nil
        print("Set active session: \(session.id), expandedSession reset")
    }
    
    private func addSession() {
        let newSession = SessionData(id: UUID())
        sessions.append(newSession)
        activeSession = newSession.id
        expandedSession = nil
        print("Added new session: \(newSession.id)")
    }
    
    private func addItem() {
        if let activeSession = activeSession {
            let newItem = ItemData(id: UUID())
            if let index = sessions.firstIndex(where: { $0.id == activeSession }) {
                sessions[index].items.append(newItem)
                activeItem = newItem.id
                print("Added new item: \(newItem.id) to session: \(activeSession)")
            }
        }
    }
}
