import SwiftUI

struct BorderOverlay: View {

    var body: some View {
        GeometryReader { geo in
            Image("Madhubani_border")                   .resizable()
                .scaledToFit()
                .frame(
                    width: geo.size.width * 0.9,
                    height: geo.size.height * 0.9
                )
                .position(
                    x: geo.size.width / 2,
                    y: geo.size.height / 2
                )
                .opacity(0)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

