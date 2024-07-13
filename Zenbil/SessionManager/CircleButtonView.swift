//
//  CircleButtonView.swift
//  Zenbil
//
//  Created by Berhan Witte on 10.07.24.
//

import SwiftUI

struct CircleButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color.white)
                .frame(width: 70, height: 70)
                .overlay(
                    Image(systemName: "camera")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                )
        }
    }
}
