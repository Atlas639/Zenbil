//
//  ItemView.swift
//  Zenbil
//
//  Created by Berhan Witte on 10.07.24.
//

import SwiftUI

struct ItemView: View {
    var item: ItemData
    var isActive: Bool
    var thumbnail: CGImage?

    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(decorative: thumbnail, scale: 1.0)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 90, height: 90)
                    .clipped()
                    .animation(.easeInOut(duration: 0.3), value: thumbnail)
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(white: 0.5))
                    .frame(width: 90, height: 90)
            }
            RoundedRectangle(cornerRadius: 3)
                .stroke(isActive ? Color.yellow : Color.clear, lineWidth: 3)
                .frame(height: 90)
        }
    }
}
