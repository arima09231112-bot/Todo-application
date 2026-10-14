import SwiftUI

/// まだ作っていないタブの仮画面。
struct ComingSoonView: View {
    let title: String
    let message: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label(title, systemImage: "hammer.fill")
            } description: {
                Text(message)
            }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
