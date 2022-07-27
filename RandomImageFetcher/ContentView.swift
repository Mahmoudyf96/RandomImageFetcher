//
//  ContentView.swift
//  RandomImageFetcher
//
//  Created by McMoodie on 2022-07-24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var photoVM: PhotoViewModel = PhotoViewModel()
    @ObservedObject var wheelVM: WheelViewModel = WheelViewModel()
    
    var body: some View {
        if photoVM.authorized {
            Main(wheelVM: wheelVM, photoVM: photoVM)
        } else {
            Onboarding(photoVM: photoVM)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
