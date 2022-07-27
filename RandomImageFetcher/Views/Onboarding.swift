//
//  Onboarding.swift
//  RandomImageFetcher
//
//  Created by McMoodie on 2022-07-24.
//

import SwiftUI

struct Onboarding: View {
    
    @ObservedObject var photoVM: PhotoViewModel
    
    var body: some View {
        VStack {
            if photoVM.denied {
                Spacer()
                Text("This app requires access to your photos")
                    .font(.subheadline)
                    .padding()
                Button {
                    photoVM.navToSettings()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 25.0)
                            .foregroundColor(.primary)
                        Text("Open Settings")
                            .foregroundColor(.black)
                            .font(.subheadline.bold().smallCaps())
                    }
                }
                .frame(width: 150, height: 50)
                .buttonStyle(.plain)
                Spacer()
            } else {
                Text("Photo Access")
                    .font(.title.bold())
                Text("Please allow access to your photos for the app to run properly")
                    .font(.caption.smallCaps())
                    .multilineTextAlignment(.center)
                Spacer()
                    .frame(height: UIScreen.main.bounds.size.height / 2)
            }
        }
    }
}

struct Onboarding_Previews: PreviewProvider {
    static var previews: some View {
        Onboarding(photoVM: PhotoViewModel())
    }
}
