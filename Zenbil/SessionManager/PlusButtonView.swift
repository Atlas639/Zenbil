//
//  PlusButtonView.swift
//  Zenbil
//
//  Created by Berhan Witte on 10.07.24.
//

import SwiftUI

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
