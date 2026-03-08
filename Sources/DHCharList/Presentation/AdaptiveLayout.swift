import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
extension View {
    @ViewBuilder
    func formContentWidth(maxWidth: CGFloat = 900) -> some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            let readableWidth = min(maxWidth, UIScreen.main.bounds.width * 0.76)
            self
                .frame(maxWidth: readableWidth)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 20)
        } else {
            self
        }
        #else
        self
        #endif
    }

    @ViewBuilder
    func platformInsetGroupedListStyle() -> some View {
        #if os(iOS)
        self.listStyle(.insetGrouped)
        #else
        self
        #endif
    }
}
#endif
