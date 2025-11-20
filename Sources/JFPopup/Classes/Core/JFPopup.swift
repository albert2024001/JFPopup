//
//  Popup.swift
//  PopupKit
//
//  Created by 逸风 on 2021/10/9.
//
import JRBaseKit
import UIKit

private let supportDynamicIsLandList = [
    "iPhone 14 Pro",
    "iPhone 14 Pro Max",
]

public var JFIsSupportDynamicIsLand: Bool {
    var t: CGFloat = 0
    if #available(iOS 11.0, *) {
        t = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0
    }
    return t == 59.0
}

public struct JFPopup<Base> {
    public let base: Base
    init(_ base: Base) {
        self.base = base
    }
}

public protocol JFPopupCompatible {}
public extension JFPopupCompatible {
    static var popup: JFPopup<Self>.Type {
        set {}
        get { JFPopup<Self>.self }
    }

    var popup: JFPopup<Self> {
        set {}
        get { JFPopup(self) }
    }
}

public protocol JFPopupProtocol {
    var dataSource: JFPopupDataSource? { get set }
    var popupProtocol: JFPopupAnimationProtocol? { get set }
    var container: UIView? { get set }
    var config: JFPopupConfig { get set }
    func autoDismissHandle()
    func dismissPopupView(completion: @escaping ((_ isFinished: Bool) -> Void))
}

@objc public enum JFPopupAnimationDirection: Int {
    case unowned
    case left
    case right
}

@objc public enum JFPopupAnimationType: Int {
    case dialog
    case bottomSheet
    case drawer
}

@objc public protocol JFPopupDataSource: AnyObject {
    @objc func viewForContainer() -> UIView?
}

public protocol JFPopupAnimationProtocol: AnyObject {
    func present(with transitonContext: UIViewControllerContextTransitioning?, config: JFPopupConfig, contianerView: UIView, completion: ((_ isFinished: Bool) -> Void)?)
    func dismiss(with transitonContext: UIViewControllerContextTransitioning?, config: JFPopupConfig, contianerView: UIView?, completion: ((_ isFinished: Bool) -> Void)?)
}

public enum JFTimerDuration {
    /// 纳秒
    case nanoseconds(value: UInt32)
    /// 微妙
    case microseconds(value: UInt32)
    /// 毫秒
    case milliseconds(value: UInt32)
    /// 秒
    case seconds(value: UInt32)
    /// 分钟
    case minutes(value: UInt32)

    public func timeDuration() -> DispatchTimeInterval {
        switch self {
        case let .nanoseconds(value: value):
            return .nanoseconds(Int(value))
        case let .microseconds(value: value):
            return .microseconds(Int(value))
        case let .milliseconds(value: value):
            return .milliseconds(Int(value))
        case let .seconds(value: value):
            return .seconds(Int(value))
        case let .minutes(value: value):
            return .seconds(Int(value) * 60)
        }
    }
}

public enum JFToastPosition {
    case center
    case top
    case bottom
    case dynamicIsland // 新增灵动岛位置动画
}

public struct JFPopupConfig {
    /// background view colod
    public var bgColor: UIColor = .init(red: 0, green: 0, blue: 0, alpha: 0.4)
    /// enableUserInteraction, if true, your gesture can not transmit to super view
    public var enableUserInteraction = true
    /// popup style
    public var animationType: JFPopupAnimationType = .dialog
    /// popup the view without animation
    public var withoutAnimation = false
    /// if trie tap background can dismiss popup view
    public var isDismissible = true
    /// enable drag gesture
    public var enableDrag = true
    /// use in drawer type , from left or right direction
    public var direction: JFPopupAnimationDirection = .unowned

    /// if true will auto dismiss popup view, use duration, default is false
    public var enableAutoDismiss = false
    /// auto dismiss duration, default is 2 seconds
    public var autoDismissDuration: JFTimerDuration = .seconds(value: 2)

    /// toast view position
    public var toastPosition: JFToastPosition = JFIsSupportDynamicIsLand ? .dynamicIsland : .center

    /// static style config
    public static var dialog = JFPopupConfig(enableDrag: false)
    public static var bottomSheet = JFPopupConfig(animationType: .bottomSheet)
    public static var drawer = JFPopupConfig(animationType: .drawer, direction: .left)
}
