//
//  ContentView.swift
//  StencilCam
//
//  Created by Mike on 1/6/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.black
            CameraView()
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
