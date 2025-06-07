//
//  ItemDownloadButton.swift
//  Mediathek
//
//  Created by Jon on 03.06.25.
//

import SwiftUI

struct ItemDownloadButton: View {
    
    var item: Item

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        
        if ItemDownloadAllowed(item) {
            
            Button {
                ItemDownload(item)
                openWindow(id: "downloads")
            } label: {
                
                //                                Label("Laden", systemImage: "icloud.and.arrow.down")
                
                Image(systemName: "icloud.and.arrow.down")
                //                                    .resizable()
                //                                    .frame(width: symbolSize, height: symbolSize)
                
            }
            .buttonStyle(.bordered)
        }

    }
}

