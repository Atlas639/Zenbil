//
//  DataScannerUIVIew.swift
//  Zenbil
//
//  Created by Berhan Witte on 28.06.24.
//

import SwiftUI
import VisionKit

struct DataScannerUIView: View {
    @State private var recognizedItems: [RecognizedItem] = []
    @State private var sessions: [UUID] = []
    @State private var selectedSessions: Set<UUID> = []
    @State private var activeSession: UUID? = nil
    @State private var isSelectionMode: Bool = false
    @State private var expandedSession: UUID?
    
    @State private var viewModel = DataScannerViewModel()
    
    var body: some View {
        ZStack {
            DataScannerView(recognizedItems: $recognizedItems,
                            recognizedDataTypes: [.text(textContentType: nil), .barcode()],
                            recognizesMultipleItems: true,
                            viewModel: viewModel)
            .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                SessionScrollView(sessions: $sessions, selectedSessions: $selectedSessions, activeSession: $activeSession, isSelectionMode: $isSelectionMode, expandedSession: $expandedSession)
                .background(Color.black.opacity(0.5))
            }
            .padding(.bottom, 40)
            
            if isSelectionMode {
                TrashButton {
                    
                    withAnimation {
                        for session in selectedSessions {
                            if let index = sessions.firstIndex(of: session) {
                                sessions.remove(at: index)
                            }
                        }
                        selectedSessions.removeAll()
                        isSelectionMode = false
                    }
                }
            }
        }
    }
}

struct SessionScrollView: View {
    @Binding var sessions: [UUID]
    @Binding var selectedSessions: Set<UUID>
    @Binding var activeSession: UUID?
    @Binding var isSelectionMode: Bool
    @Binding var expandedSession: UUID?
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(sessions, id: \.self) { session in
                    SessionView(
                        session: session,
                        isSelectionMode: $isSelectionMode,
                        isSelected: selectedSessions.contains(session),
                        isActive: activeSession == session,
                        isExpanded: expandedSession == session,
                        
                        onTap: {
                            if isSelectionMode {
                                if selectedSessions.contains(session) {
                                    selectedSessions.remove(session)
                                } else {
                                    selectedSessions.insert(session)
                                }
                            } else {
                                if activeSession == session {
                                    withAnimation {
                                        if expandedSession == session {
                                            expandedSession = nil
                                        } else {
                                            expandedSession = session
                                        }
                                    }
                                } else {
                                    activeSession = session
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
                    let newSession = UUID()
                    sessions.append(newSession)
                    activeSession = newSession
                    expandedSession = nil
                }, isSelectionMode: isSelectionMode)
            }
            .padding()
        }
    }
}
    
struct SessionView: View {
    let session: UUID
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
            }
                if
                    isExpanded {
                    ExpandedSessionView()
                        .transition(.scale)
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
    
struct ExpandedSessionView: View {
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(0..<3, id: \.self) { _ in
                    ExpandedSessionView()
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
                .padding(.top, 40) // Adjust the top padding
                .padding(.trailing, 20) // Adjust the trailing padding
            }
            Spacer()
        }
        .transition(.move(edge: .top))
    }
}
                    
struct DataScannerUIView_Previews: PreviewProvider {
    static var previews: some View {
        DataScannerUIView()
    }
}
