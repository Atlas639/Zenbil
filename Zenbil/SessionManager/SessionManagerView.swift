//
//  SessionManagerView.swift
//  Zenbil
//
//  Created by Berhan Witte on 28.06.24.
//

import SwiftUI
import VisionKit

struct SessionManagerView: View {
    @State private var recognizedItems: [RecognizedItem] = []
    @State private var selectedSessions: Set<UUID> = []
    @State private var isSelectionMode: Bool = false
    @State private var expandedSession: UUID?
    @State private var capturedImage: UIImage?
    @State private var capturePhoto: Bool = false
    @State private var isPhotoMode: Bool = false
    
    @State private var cameraModel = CameraModel()
    var body: some View {
        ZStack {
            if isPhotoMode {
                CameraView(camera: cameraModel)
                    .edgesIgnoringSafeArea(.all)
            } else {
                DataScannerView(
                    recognizedItems: $recognizedItems,
                    recognizedDataTypes: [.text(textContentType: nil), .barcode()],
                    recognizesMultipleItems: true,
                    sessions: $cameraModel.sessions,
                    activeSession: $cameraModel.activeSession,
                    activeItem: $cameraModel.activeItem
                )
                .edgesIgnoringSafeArea(.all)
            }
            
            VStack {
                Spacer()
                HStack {
                    NavigationLink("Save", destination: ArticleFormView())
                }
                Spacer()
                ZStack {
                    if isPhotoMode {
                        HStack {
                            Spacer()
                            CaptureButton(camera: cameraModel)
                                .padding(.bottom, 20)
                            Spacer()
                        }
                    }
                    HStack {
                        Spacer()
                        Button {
                            withAnimation {
                                isPhotoMode.toggle()
                            }
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Circle().fill(Color.gray))
                                .clipShape(Circle())
                        }
                        .symbolEffect(.bounce, options: .repeating, value: isPhotoMode)
                        .padding(.top, 40)
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
                
                SessionScrollView(
                    sessions: $cameraModel.sessions,
                    selectedSessions: $selectedSessions,
                    activeSession: $cameraModel.activeSession,
                    activeItem: $cameraModel.activeItem,
                    isSelectionMode: $isSelectionMode,
                    expandedSession: $expandedSession,
                    thumbnails: $cameraModel.thumbnails
                )
                .background(Color.black.opacity(0.5))
            }
            .padding(.bottom, 40)
            
            if isSelectionMode {
                TrashButton {
                    withAnimation {
                        cameraModel.sessions.removeAll { session in
                            selectedSessions.contains(session.id)
                        }
                        selectedSessions.removeAll()
                        isSelectionMode = false
                    }
                }
            }
        }
        .onAppear {
            print("SessionManagerView appeared")
            Task {
                await cameraModel.start()
            }
        }
    }
}
                  
struct SessionManagerView_Previews: PreviewProvider {
    static var previews: some View {
        SessionManagerView()
    }
}
