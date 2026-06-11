//
//  ContentView.swift
//  Lampstand
//
//  Created by Israel Manzo on 6/9/26.
// https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles/en-asv/books/genesis/chapters/1.json

import SwiftUI

struct ContentView: View {
    var body: some View {
        BibleBrowserView()
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
