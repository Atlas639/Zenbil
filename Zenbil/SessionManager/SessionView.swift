//
//  SessionView.swift
//  Zenbil
//
//  Created by Berhan Witte on 10.07.24.
//

import SwiftUI

struct SessionView: View {
    let session: SessionData
    @Binding var sessions: [SessionData]
    @Binding var isSelectionMode: Bool
    @Binding var activeItem: UUID?
    let isSelected: Bool
    let isActive: Bool
    let isExpanded: Bool
    @Binding var thumbnails: [UUID: CGImage]
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        VStack {
            if isSelectionMode {
                Circle()
                    .fill(isSelected ? Color.yellow : Color(white: 0.3))
                    .stroke(Color(white: 0.3), lineWidth: 1)
                    .frame(width: 25, height: 25)
                    .overlay(isSelected ? Image(systemName: "checkmark").foregroundColor(.white) : nil)
                    .onTapGesture {
                        print("Tapped selection circle for session: \(session.id)")
                        onTap()
                    }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isActive ? Color.blue : Color.clear, lineWidth: 3)
                    .frame(height: 90)
                
                if isExpanded {
                    ItemScrollView(items: Binding(get: {
                        session.items
                    }, set: { newItems in
                        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                            sessions[index].items = newItems
                        }
                    }), activeItem: $activeItem,
                        thumbnails: $thumbnails)
                        .transition(.slide)
                } else {
                    if let thumbnail = session.items.first(where: { $0.id == activeItem })?.thumbnail { // 
                        Image(decorative: thumbnail, scale: 1.0)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 90, height: 90)
                            .clipped()
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: thumbnail)
                            .onAppear {
                                print("Displaying thumbnail for session: \(session.id)")
                            }
                    } else {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(white: 0.3))
                            .frame(width: 90, height: 90)
                    }
                    
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(isActive ? Color.blue : Color.clear, lineWidth: 3)
                        .frame(width: 90, height: 90)
                }
            }
            .onTapGesture {
                print("Tapped session view for session: \(session.id)")
                onTap()
            }
            .onLongPressGesture {
                print("Long pressed session view for session: \(session.id)")
                onLongPress()
            }
        }
    }
}
