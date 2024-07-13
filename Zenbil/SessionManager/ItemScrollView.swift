//
//  ItemScrollView.swift
//  Zenbil
//
//  Created by Berhan Witte on 10.07.24.
//

import SwiftUI

struct ItemScrollView: View {
    @Binding var items: [ItemData]
    @Binding var activeItem: UUID?
    @Binding var thumbnails: [UUID: CGImage]
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(items, id: \.id) { item in
                    ItemView(
                        item: item,
                        isActive: item.id == activeItem,
                        thumbnail: thumbnails[item.id])
                        .onTapGesture {
                            activeItem = item.id
                        }
                }
                PlusButton(action: addItem, isSelectionMode: false)
            }
            .padding()
        }
    }
    
    private func addItem() {
        let newItem = ItemData(id: UUID())
        items.append(newItem)
        activeItem = newItem.id
    }
}
