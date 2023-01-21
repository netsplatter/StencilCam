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
    @State private var showGrid: Bool = false
    @State private var sliderValue: Double = 50.0
    @State private var rotation: Double = 0.0
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var controlColumns: [GridItem] = [
        GridItem(.fixed(90)),
        GridItem(.fixed(90)),
        GridItem(.fixed(90))
    ]
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        
                    }) {
                        Image("flash-on")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                    }
                    .disabled(self.cameraError)
                    .opacity(self.cameraError ? 0.7 : 1)
                    .rotationEffect(.degrees(rotation))
                    
                    Spacer()
                    
                    Button(action: {
                        showGrid.toggle()
                    }) {
                        Image("grid")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                    }
                    .disabled(self.cameraError)
                    .opacity(self.cameraError ? 0.7 : 1)
                }
                .padding(.top, 45)
                .padding(.leading, 10)
                .padding(.trailing, 15)
                
                Spacer()
                
                ZStack {
                    Button(action: {
                        cameraViewController.capturePhoto()
                    }) {
                        Image("shot")
                            .resizable()
                            .frame(width: 80, height: 80)
                    }
                    .disabled(self.cameraError)
                    .opacity(self.cameraError ? 0.7 : 1)
                    
                    HStack {
                        Button(action: {
                            cameraViewController.importImage()
                        }) {
                            Image(uiImage: cameraViewController.libraryPic)
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                                .zIndex(3)
                                .rotationEffect(.degrees(rotation))
                        }
                        
                        Spacer()
                    }
                }
                .padding(.bottom, 20)
                .padding([.leading, .trailing], 15)
            }
            .zIndex(3)
            
            Camera(cameraViewController: cameraViewController, cameraSwitchID: $cameraSwitchID)
                .zIndex(1)
                .alert(isPresented: $cameraError) {
                    Alert(
                        title: Text("No Camera"),
                        message: Text("No camera available on this device."),
                        dismissButton: .default(Text("OK"), action: { cameraError = true })
                    )
                }
            
            if cameraViewController.showOverlay {
                ZStack {
                    Color.black
                    Image(uiImage: cameraViewController.imageOverlay)
                        .resizable()
                        .scaledToFit()
                }
                .opacity(sliderValue / 100)
                .zIndex(2)
                
                SliderView(value: $sliderValue)
                    .zIndex(4)
                    .rotationEffect(.degrees(90))
                    .offset(x: -UIScreen.main.bounds.size.width / 2.3)
            }
            
            if cameraViewController.flashEffect {
                FlashEffectView().zIndex(4)
            }
            
            if showGrid {
                GridView()
                    .zIndex(2)
            }
        }
        .onChange(of: cameraViewController.deviceOrientation) { orientation in
            withAnimation(.easeInOut) {
                switch orientation {
                case .portrait: rotation = 0.0
                case .portraitUpsideDown: rotation = 180.0
                case .landscapeLeft: rotation = 270.0
                case .landscapeRight: rotation = 90.0
                default: break
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
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

struct SliderView: UIViewRepresentable {
    var value: Binding<Double>
    
    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider()
        slider.value = Float(value.wrappedValue)
        slider.maximumValue = 100
        slider.minimumValue = 0
        slider.minimumTrackTintColor = .white
        
        slider.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged), for: .valueChanged)
        return slider
    }

    class Coordinator {
        var value: Binding<Double>

        init(value: Binding<Double>) {
            self.value = value
        }

        @objc func valueChanged(_ sender: UISlider) {
            value.wrappedValue = Double(sender.value)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(value: value)
    }
    
    func updateUIView(_ uiView: UISlider, context: Context) {
        uiView.value = Float(value.wrappedValue)
    }
}
