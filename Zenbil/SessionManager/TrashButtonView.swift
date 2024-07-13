//
//  TrashButtonView.swift
//  Zenbil
//
//  Created by Berhan Witte on 10.07.24.
//

import SwiftUI

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
