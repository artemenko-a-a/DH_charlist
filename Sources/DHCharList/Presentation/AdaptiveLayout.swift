import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17, macOS 14, *)
extension View {
    @ViewBuilder
    func formContentWidth(maxWidth: CGFloat = 760) -> some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            self
                .frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity, alignment: .center)
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
