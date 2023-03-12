//
//  ContentView.swift
//  DKU Explorer
//

import SwiftUI
import RealityKit


struct Tabbar: View {
    var body: some View {
        TabView {
            HStack(alignment: .bottom) {
                HomeARView()
            }
            .tabItem {
                Image(systemName: "camera.fill")
                Text("AR")
            }
            HStack {
                InfoView()
            }
            .tabItem {
                Image(systemName: "info.bubble.fill")
                Text("Info")
                    .padding()
            }
        }
        .accentColor(.blue)
        .tabViewStyle(DefaultTabViewStyle())
    }
}


struct ContentView : View {
    var body: some View {
        Tabbar()
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
