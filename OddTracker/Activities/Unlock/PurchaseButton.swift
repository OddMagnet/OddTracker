//
//  PurchaseButton.swift
//  OddTracker
//
//  Created by Michael Brünen on 19.05.21.
//

import SwiftUI

struct PurchaseButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: 200, minHeight: 44)
            .background(Color("Light Blue"))
            .clipShape(Capsule())
            .foregroundColor(.white)
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}

private struct PurchaseButtonDemoView: View {
    var body: some View {
        Button("Hello World!") {
            print("Hello Developer!")
        }
        .buttonStyle(PurchaseButton())
    }
}

struct PurchaseButton_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseButtonDemoView()
    }
}
