//
//  DataManagerView.swift
//  Zenbil
//
//  Created by Berhan Witte on 28.06.24.
//

import SwiftUI
import VisionKit

struct DataManagerView: View {
    @State private var recognizedItems: [RecognizedItem] = []
    @State private var sessions: [SessionData] = []
    @State private var selectedSessions: Set<UUID> = []
    @State private var activeSession: UUID? = nil
    @State private var activeItem: UUID? = nil
    @State private var isSelectionMode: Bool = false
    @State private var expandedSession: UUID?
    @State private var capturedImage: UIImage?
    @State private var capturePhoto: Bool = false
    
    
    var body: some View {
        ZStack {
            DataCaptureView(recognizedItems: $recognizedItems,
                            recognizedDataTypes: [.text(textContentType: nil), .barcode()],
                            recognizesMultipleItems: true,
                            sessions: $sessions,
                            activeSession: $activeSession,
                            activeItem: $activeItem,
                            capturedImage: $capturedImage,
                            capturePhoto: $capturePhoto)
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    CircleButton(action: {
                        capturePhoto = true
                    })
                    .padding(.bottom, 20)
                    Spacer()
                }
                
                SessionScrollView(sessions: $sessions, selectedSessions: $selectedSessions, activeSession: $activeSession, isSelectionMode: $isSelectionMode, expandedSession: $expandedSession)
                .background(Color.black.opacity(0.5))
            }
            .padding(.bottom, 40)
            
            if isSelectionMode {
                TrashButton {
                    
                    withAnimation {
                        sessions.removeAll { session in
                            selectedSessions.contains(session.id)
                        }
                        selectedSessions.removeAll()
                        isSelectionMode = false
                    }
                }
            }
        }
    }
}

struct CircleButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color.blue)
                .frame(width: 70, height: 70)
                .overlay(
                    Image(systemName: "camera")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                )
        }
    }
}

struct SessionScrollView: View {
    @Binding var sessions: [SessionData]
    @Binding var selectedSessions: Set<UUID>
    @Binding var activeSession: UUID?
    @Binding var isSelectionMode: Bool
    @Binding var expandedSession: UUID?
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(sessions, id: \.id) { session in
                    SessionView(
                        session: session,
                        isSelectionMode: $isSelectionMode,
                        isSelected: selectedSessions.contains(session.id),
                        isActive: activeSession == session.id,
                        isExpanded: expandedSession == session.id,
                        
                        onTap: {
                            if isSelectionMode {
                                if selectedSessions.contains(session.id) {
                                    selectedSessions.remove(session.id)
                                } else {
                                    selectedSessions.insert(session.id)
                                }
                            } else {
                                if activeSession == session.id {
                                    withAnimation {
                                        if expandedSession == session.id {
                                            expandedSession = nil
                                        } else {
                                            expandedSession = session.id
                                        }
                                    }
                                } else {
                                    activeSession = session.id
                                    expandedSession = nil
                                }
                            }
                        },
                        onLongPress: {
                            withAnimation {
                                isSelectionMode = true
                            }
                            let impactFeedbackgenerator = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedbackgenerator.impactOccurred()
                        }
                    )
                }
                
                PlusButton(action: {
                    let newSession = SessionData(id: UUID(), barcodes: [], texts: [])
                    sessions.append(newSession)
                    activeSession = newSession.id
                    expandedSession = nil
                }, isSelectionMode: isSelectionMode)
            }
            .padding()
        }
    }
}
    
struct SessionView: View {
    let session: SessionData
    @Binding var isSelectionMode: Bool
    let isSelected: Bool
    let isActive: Bool
    let isExpanded: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        VStack {
            if isSelectionMode {
                Circle ()
                    .fill(isSelected ? Color.yellow : Color(white: 0.3))
                    .stroke(Color(white: 0.3), lineWidth: 1)
                    .frame(width: 25, height: 25)
                    .overlay(isSelected ? Image(systemName: "checkmark").foregroundColor(.white) : nil)
                    .onTapGesture {
                        onTap()
                    }
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isActive ? Color.blue : Color.clear, lineWidth: 3)
                    .frame(height: 90)
                if
                    isExpanded {
                    ExpandedSessionView()
                        .transition(.slide)
                        .onTapGesture {
                            onTap()
                        }
                } else {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(white: 0.3))
                        .frame(width: 90, height: 90)
                        .onTapGesture {
                            onTap()
                        }
                        .onLongPressGesture {
                            onLongPress()
                        }
                }
            }
        }
    }
}
    
struct ExpandedSessionView: View {
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(0..<3, id: \.self) { _ in
                    ItemView()
                }
            }
        }
    }
}
    
struct ItemView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(white: 0.5))
            .frame(width: 90, height: 90)
    }
}

struct PlusButton: View {
    let action: () -> Void
    let isSelectionMode: Bool
    
    var body: some View {
        VStack {
            if isSelectionMode {
                Spacer()
                    .frame(height: 30)
            }
            Button(action: action) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.2))
                    .frame(width: 90, height: 90)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.largeTitle)
                            .foregroundColor(Color.white.opacity(0.7))
                    )
            }
        }
    }
}

struct TrashButton: View {
    let action: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: action) {
                    Image(systemName: "trash")
                        .font(.title)
                        .foregroundColor(.red)
                        .padding()
                }
                .padding(.top, 40)
                .padding(.trailing, 20)
            }
            Spacer()
        }
        .transition(.move(edge: .top))
    }
}
                    
struct DataManagerView_Previews: PreviewProvider {
    static var previews: some View {
        DataManagerView()
    }
}