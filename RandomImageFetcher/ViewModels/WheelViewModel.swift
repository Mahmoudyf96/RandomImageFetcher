//
//  WheelViewModel.swift
//  RandomImageFetcher
//
//  Created by McMoodie on 2022-07-25.
//

import SwiftUI

class WheelViewModel: ObservableObject {
    @Published var currentValue: Double = 0.0
    @Published var currentProgress: CGFloat = 0.0001
    
    func randomPosition() {
        withAnimation {
            self.currentValue = Double.random(in: 0...360)
            self.currentProgress = currentValue / 360
        }
    }
    
    func onDrag(value: DragGesture.Value) {
        let vector = CGVector(dx: value.location.x, dy: value.location.y)
        
        let radians = atan2(vector.dy - 15, vector.dx - 15)
        
        var angle = radians * 180 / .pi
        if angle < 0 { angle = 360 + angle }
        
        let progress =  angle / 360
        
        self.currentValue = angle
        self.currentProgress = progress
    }
}
