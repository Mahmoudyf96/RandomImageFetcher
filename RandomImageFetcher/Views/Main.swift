//
//  Main.swift
//  RandomImageFetcher
//
//  Created by McMoodie on 2022-07-24.
//

import SwiftUI

struct Main: View {
    @ObservedObject var wheelVM: WheelViewModel
    @ObservedObject var photoVM: PhotoViewModel
    
    let gridItem = GridItem(.flexible(minimum: 0), spacing: 0)
    
    var body: some View {
        VStack {
            Spacer()
            Button {
                photoVM.makeAPICalls.toggle()
            } label: {
                HStack {
                    Image(systemName: photoVM.makeAPICalls ? "record.circle" : "circle")
                    Text("Make API Calls")
                }
            }
            .padding()
            RandomImageWheel()
            RandomImageFetcher()
            Spacer()
        }
        .background(
            ZStack {
                Image(uiImage: photoVM.currentCameraPhoto)
                    .resizable()
                    .scaledToFill()
                Color.black.opacity(0.54)
            }
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    @ViewBuilder
    func RandomImageWheel() -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 40)
                Circle()
                    .trim(from: 0, to: wheelVM.currentProgress)
                    .stroke(.white, style: StrokeStyle(lineWidth: 40, lineCap: .round, lineJoin: .round))
                    .rotationEffect(.init(degrees: -90))
                // Button 1 -> Reveals degrees position
                Text("\(wheelVM.currentValue, specifier: "%.0f")")
                    .font(.caption.bold().smallCaps())
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .rotationEffect(.init(degrees: 90))
                    .rotationEffect(.init(degrees: -wheelVM.currentValue))
                    .background(.green, in: Circle())
                    .offset(x: width / 2)
                    .rotationEffect(.init(degrees: wheelVM.currentValue))
                    .onTapGesture {
                        // Button 1 Tapped -> animate to random position on the circle
                        wheelVM.randomPosition()
                        photoVM.changeCurrentPhoto(currentWheelValue: wheelVM.currentValue)
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                wheelVM.onDrag(value: value)
                                photoVM.changeCurrentPhoto(currentWheelValue: wheelVM.currentValue)
                            }
                    )
                    .rotationEffect(.init(degrees: -90))
                    .disabled(photoVM.photoBusy || photoVM.apiBusy)
                VStack {
                    Text("\(wheelVM.currentValue, specifier: "%.0f")")
                        .font(.largeTitle.bold())
                    Text("Degrees")
                        .font(.callout.smallCaps())
                        .opacity(0.6)
                }
            }
        }
        .frame(width: screenBounds().width / 1.6, height: screenBounds().height / 2.5)
        .padding()
    }
    
    @ViewBuilder
    func RandomImageFetcher() -> some View {
        VStack {
            Button {
                DispatchQueue.main.async {
                    photoVM.fetchRandomPhotos() {
                        photoVM.changeCurrentPhoto(currentWheelValue: wheelVM.currentValue)
                    }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 25.0)
                        .foregroundColor(.primary)
                    Text("Generate")
                        .foregroundColor(.black)
                        .font(.subheadline.bold().smallCaps())
                }
            }
            .frame(width: 150, height: 50)
            .buttonStyle(.plain)
            .disabled(photoVM.photoBusy || photoVM.apiBusy)
            LazyVGrid(columns: Array(repeating: gridItem, count: 5), alignment: .center, spacing: 15) {
                if photoVM.photos.isEmpty {
                    ForEach(0..<10) { _ in
                        RoundedRectangle(cornerRadius: 10.0)
                            .foregroundColor(.white.opacity(0.1))
                            .frame(width: 50, height: 50)
                    }
                } else if photoVM.photos.count < 10 {
                    ForEach(photoVM.photos, id: \.self) { photo in
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 10.0))
                    }
                    ForEach(0..<(10-photoVM.photos.count), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 10.0)
                            .foregroundColor(.white.opacity(0.1))
                            .frame(width: 50, height: 50)
                    }
                } else {
                    ForEach(photoVM.photos, id: \.self) { photo in
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 10.0))
                    }
                }
            }
            .frame(width: screenBounds().width / 1.15, height: screenBounds().height / 3.0 - 50)
            .padding()
            ProgressView("Fetching Photos...", value: photoVM.photoProgress, total: Double(photoVM.numOfPhotos))
                .opacity((photoVM.photoBusy || photoVM.apiBusy) ? 1 : 0)
            Spacer()
        }
        .frame(width: screenBounds().width / 1.15, height: screenBounds().height / 3.0)
        .padding()
    }
}

struct Main_Previews: PreviewProvider {
    static var previews: some View {
        Main(wheelVM: WheelViewModel(), photoVM: PhotoViewModel())
    }
}
