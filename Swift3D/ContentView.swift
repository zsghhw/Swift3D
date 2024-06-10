//
//  ContentView.swift
//  Swift3D
//
//  Created by 张训 on 2024/6/10.
//

import SwiftUI
import SceneKit
struct ContentView: View {
    
    
    
    var body: some View {
        Flip3D(scene: Flip3D.boxScene,options: [.setCamera])
            
    }
}

#Preview {
    ContentView()
}
