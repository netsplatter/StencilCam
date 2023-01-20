//
//  CameraView.swift
//  StencilCam
//
//  Created by Mike on 1/11/23.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var cameraViewController = CameraViewController()
    
    @State private var cameraError = false
    @State private var cameraSwitchID: UUID? = nil
    @State private var recordingID: UUID? = nil
    @State private var videoPickerID: UUID? = nil
    @State private var isRecording: Bool = false
    @State private var recTimer = 0
    @State private var recTimerIsActive = false
    @State private var showRecIcon = false
    @State private var timerColor = Color.black
    @State private var showNextView = false
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var controlColumns: [GridItem] = [
        GridItem(.fixed(90)),
        GridItem(.fixed(90)),
        GridItem(.fixed(90))
    ]
    
    var body: some View {
        ZStack {
            VStack {
                
                Spacer()
                
                LazyVGrid (
                    columns: controlColumns,
                    alignment: .center
                ) {
                    ForEach(0...2, id: \.self) { index in
                        switch index {
                        case 0:
                            if !self.isRecording {
                                Button(action: {
                                    
                                }) {
                                    Image(uiImage: cameraViewController.libraryPic)
                                }
                            }
                            
                        case 1:
                            Button(action: {
                                cameraViewController.capturePhoto()
                            }) {
                                Image("shot")
                            }
                            .disabled(self.cameraError)
                            .opacity(self.cameraError ? 0.7 : 1)
                            
                        case 2:
                           Spacer()
                            
                        default: EmptyView()
                        }
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
            .zIndex(2)
            
            Camera(cameraViewController: cameraViewController, cameraSwitchID: $cameraSwitchID)
                .zIndex(1)
                .alert(isPresented: $cameraError) {
                    Alert(
                        title: Text("No Camera"),
                        message: Text("No camera available on this device."),
                        dismissButton: .default(Text("OK"), action: { cameraError = true })
                    )
                }
            
            if cameraViewController.flashEffect {
                FlashEffectView().zIndex(2)
            }
        }
        //.background(Color.black)
       // .edgesIgnoringSafeArea(.all)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    self.cameraSwitchID = UUID()
                }) {
                    Image("flash-auto")
                }
                .buttonStyle(PlainButtonStyle())
                .zIndex(2)
                .disabled(self.cameraError)
                .opacity(self.cameraError ? 0.7 : 1)
            }
            
            ToolbarItem(placement: .principal) {
                Button(action: {
                    self.cameraSwitchID = UUID()
                }) {
                    Image("grid")
                }
                .buttonStyle(PlainButtonStyle())
                .zIndex(2)
                .disabled(self.cameraError)
                .opacity(self.cameraError ? 0.7 : 1)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    self.cameraSwitchID = UUID()
                }) {
                    Image("camera-switch")
                }
                .buttonStyle(PlainButtonStyle())
                .zIndex(2)
                .disabled(self.cameraError)
                .opacity(self.cameraError ? 0.7 : 1)
            }
        }
       // .navigationBarBackButtonHidden(true)
       // .ignoresSafeArea(.container)
        .gesture(DragGesture(minimumDistance: 30, coordinateSpace: .global).onEnded { value in
            let horizontalAmount = value.translation.width as CGFloat
            let verticalAmount = value.translation.height as CGFloat
            
            if abs(horizontalAmount) > abs(verticalAmount) {
                if horizontalAmount < 0 {
                    // swipe left
                } else {
                    // swipe right
                   
                }
            } else {
                if verticalAmount < 0 {
                    // swipe up
                    
                } else {
                    // swipe down
                    
                }
            }
        })
    }
}

struct Camera: UIViewControllerRepresentable {
    var cameraViewController: CameraViewController
    @Binding var cameraSwitchID: UUID?
            
    class Coordinator {
        var previousCameraSwitchID: UUID? = nil
    }

    func makeUIViewController(context: Context) -> CameraViewController {
        return cameraViewController
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
//        if cameraSwitchID != context.coordinator.previousCameraSwitchID {
//            try? uiViewController.switchCamera()
//            context.coordinator.previousCameraSwitchID = cameraSwitchID
//        }
        
//        if videoPickerID != context.coordinator.previousVideoPickerID {
//            uiViewController.openVideoGallery()
//        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
}

struct FlashEffectView: View {
    var body: some View {
        Color.white
    }
}
