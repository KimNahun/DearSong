import SwiftUI
import UIKit

// MARK: - Keyboard Dismiss

extension View {
    /// 바깥 영역 탭 시 키보드를 닫는 modifier.
    /// 앱 전체에서 글로벌로 적용하여 모든 화면에서 동작한다.
    /// 바깥 영역 탭 시 키보드를 닫는다. simultaneousGesture를 사용하여
    /// 버튼·NavigationLink 등의 탭 핸들링을 가로채지 않는다.
    /// sheet/fullScreenCover는 별도 뷰 트리이므로 각 루트에 직접 적용해야 한다.
    func dismissKeyboardOnTap() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
        )
    }
}
