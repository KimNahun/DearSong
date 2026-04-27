import SwiftUI
import UIKit

// MARK: - Keyboard Dismiss

extension View {
    /// 바깥 영역 탭 시 키보드를 닫는 modifier.
    /// 앱 전체에서 글로벌로 적용하여 모든 화면에서 동작한다.
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
}
