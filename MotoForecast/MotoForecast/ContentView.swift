//
//  ContentView.swift
//  MotoForecast
//
//  Created by Imani Aza on 4/18/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "smiley")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, baby!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
