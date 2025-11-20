//
//  JFPopupView.swift
//  JFPopup
//
//  Created by 逸风 on 2021/10/18.
//

import UIKit

/// popup va custom view use in view, not controller
public extension JFPopup where Base: JFPopupView {
    /// popup a bottomSheet with your custom view
    /// - Parameters:
    ///   - isDismissible: default true, will tap bg auto dismiss
    ///   - enableDrag: default true, will enable drag animate
    ///   - bgColor: background view color
    ///   - container: your custom view
    @discardableResult static func bottomSheet(with isDismissible: Bool = true, enableDrag: Bool = true, bgColor: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4), yourView: UIView? = nil, container: @escaping (_ mainContainer: JFPopupView?) -> UIView) -> JFPopupView? {
        var config: JFPopupConfig = .bottomSheet
        config.isDismissible = isDismissible
        config.enableDrag = enableDrag
        config.bgColor = bgColor
        return custom(with: config, yourView: yourView) { mainContainer in
            container(mainContainer)
        }
    }

    /// popup a drawer style view with your custom view
    /// - Parameters:
    ///   - direction: left or right
    ///   - isDismissible: default true, will tap bg auto dismiss
    ///   - enableDrag: default true, will enable drag animate
    ///   - bgColor: background view color
    ///   - container: your custom view
    @discardableResult static func drawer(with direction: JFPopupAnimationDirection = .left, isDismissible: Bool = true, enableDrag: Bool = true, bgColor: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4), yourView: UIView? = nil, container: @escaping (_ mainContainer: JFPopupView?) -> UIView) -> JFPopupView? {
        var config: JFPopupConfig = .drawer
        config.direction = direction
        config.isDismissible = isDismissible
        config.enableDrag = enableDrag
        config.bgColor = bgColor
        return custom(with: config, yourView: yourView) { mainContainer in
            container(mainContainer)
        }
    }

    /// popup a dialog style view with your custom view
    /// - Parameters:
    ///   - isDismissible: default true, will tap bg auto dismiss
    ///   - bgColor: background view color
    ///   - container: your custom view
    @discardableResult static func dialog(with isDismissible: Bool = true, bgColor: UIColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4), yourView: UIView? = nil, container: @escaping (_ mainContainer: JFPopupView?) -> UIView) -> JFPopupView? {
        var config: JFPopupConfig = .dialog
        config.isDismissible = isDismissible
        config.bgColor = bgColor
        return custom(with: config, yourView: yourView) { mainContainer in
            container(mainContainer)
        }
    }

    /// popup a custom view with custom config
    /// - Parameters:
    ///   - config: popup config
    ///   - container: your custom view
    @discardableResult static func custom(with config: JFPopupConfig, yourView: UIView? = nil, container: @escaping (_ mainContainer: JFPopupView?) -> UIView?) -> JFPopupView? {
        if Thread.current != Thread.main {
            return DispatchQueue.main.sync {
                let v = JFPopupView(with: config) { mainContainer in
                    container(mainContainer)
                }
                v.popup(into: yourView)
                return v
            }
        } else {
            let v = JFPopupView(with: config) { mainContainer in
                container(mainContainer)
            }
            v.popup(into: yourView)
            return v
        }
    }
}

extension JFPopupView: JFPopupProtocol {
    public func dismissPopupView(completion: @escaping ((Bool) -> Void)) {
        popupProtocol?.dismiss(with: nil, config: config, contianerView: container, completion: { [weak self] isFinished in
            self?.removeFromSuperview()
            completion(isFinished)
        })
    }

    public func autoDismissHandle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + config.autoDismissDuration.timeDuration()) {
            self.dismissPopupView { _ in
            }
        }
    }
}

public class JFPopupView: UIView {
    var beginTouchPoint: CGPoint = .zero
    var beginFrame: CGRect = .zero

    public weak var dataSource: JFPopupDataSource?

    public weak var popupProtocol: JFPopupAnimationProtocol?

    public var container: UIView?

    public var config: JFPopupConfig = .dialog

    deinit {
        print("JFPopupView dealloc")
    }

    public init(with config: JFPopupConfig, container: ((_ mainContainer: JFPopupView?) -> UIView?)?) {
        super.init(frame: UIScreen.main.bounds)
        self.container = container?(self)
        self.config = config
        configSubview()
        configGest()
    }

    public init(with config: JFPopupConfig, popupProtocol: JFPopupAnimationProtocol? = nil, container: ((_ mainContainer: JFPopupView?) -> UIView?)?) {
        super.init(frame: UIScreen.main.bounds)
        self.popupProtocol = popupProtocol
        self.container = container?(self)
        self.config = config
        configSubview()
        configGest()
    }

    func configSubview() {
        isUserInteractionEnabled = config.enableUserInteraction
        backgroundColor = config.bgColor
        if popupProtocol == nil {
            popupProtocol = self
        }
        if let container = container {
            addSubview(container)
        } else {
            if dataSource == nil {
                dataSource = self
            }
            if let v = dataSource?.viewForContainer() {
                addSubview(v)
                container = v
            }
        }
    }

    func configGest() {
        let panGest = UIPanGestureRecognizer(target: self, action: #selector(onPan(gest:)))
        panGest.delegate = self
        addGestureRecognizer(panGest)
        let tapGest = UITapGestureRecognizer(target: self, action: #selector(tapBGAction))
        tapGest.delegate = self
        addGestureRecognizer(tapGest)
    }

    @objc func tapBGAction() {
        guard config.isDismissible else { return }
        dismissPopupView { _ in
        }
    }

    func popup(into yourView: UIView? = nil) {
        guard let view = container else { return }
        guard let window = UIApplication.shared.windows.first(where: \.isKeyWindow) else { return }
        if let view = yourView {
            view.addSubview(self)
        } else {
            window.addSubview(self)
        }
        popupProtocol?.present(with: nil, config: config, contianerView: view, completion: { [weak self] _ in
            guard self?.config.enableAutoDismiss == true else { return }
            self?.autoDismissHandle()
        })
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension JFPopupView: UIGestureRecognizerDelegate {
    @objc private func onPan(gest: UIPanGestureRecognizer) {
        guard config.enableDrag else {
            tapBGAction()
            return
        }
        guard let container = container else { return }
        switch gest.state {
        case .began:
            beginFrame = container.frame
            beginTouchPoint = gest.location(in: self)
        case .changed:
            guard config.animationType != .dialog else { break }
            self.container?.frame = getRectForPan(pan: gest)
        case .ended, .cancelled:
            guard config.animationType != .dialog else {
                tapBGAction()
                break
            }
            self.container?.frame = getRectForPan(pan: gest)
            let isClosed: Bool = checkGestToClose(gest: gest)
            if isClosed == true {
                tapBGAction()
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.container?.frame = self.beginFrame
                }
            }
        default:
            break
        }
    }

    private func checkGestToClose(gest: UIPanGestureRecognizer) -> Bool {
        if config.animationType == .drawer {
            if config.direction == .left {
                return gest.velocity(in: container).x < 0
            } else {
                return gest.velocity(in: container).x > 0
            }
        } else if config.animationType == .bottomSheet {
            return gest.velocity(in: container).y > 0
        }
        return false
    }

    private func getRectForPan(pan: UIPanGestureRecognizer) -> CGRect {
        guard let view = container else { return .zero }
        var rect: CGRect = view.frame
        let currentTouch = pan.location(in: self)
        if config.animationType == .drawer {
            let xRate = (beginTouchPoint.x - beginFrame.origin.x) / beginFrame.size.width
            let currentTouchDeltaX = xRate * view.jf.width
            var x = currentTouch.x - currentTouchDeltaX
            if x < beginFrame.origin.x && config.direction == .right {
                x = beginFrame.origin.x
            } else if x > beginFrame.origin.x && config.direction == .left {
                x = beginFrame.origin.x
            }

            rect.origin.x = x
        } else if config.animationType == .bottomSheet {
            let yRate = (beginTouchPoint.y - beginFrame.origin.y) / beginFrame.size.height
            let currentTouchDeltaY = yRate * view.jf.height
            var y = currentTouch.y - currentTouchDeltaY
            if y < beginFrame.origin.y {
                y = beginFrame.origin.y
            }
            rect.origin.y = y
        }
        return rect
    }

    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let isTapGest = gestureRecognizer is UITapGestureRecognizer
        let point = gestureRecognizer.location(in: gestureRecognizer.view)
        let rect = container?.frame ?? .zero
        let inContianer = rect.contains(point)
        if isTapGest {
            if inContianer {
                return false
            }
            if config.isDismissible == false {
                return false
            }
        } else {
            if config.enableDrag == false || config.isDismissible == false {
                return false
            }
        }
        return true
    }
}

extension JFPopupView: JFPopupDataSource {
    @objc public func viewForContainer() -> UIView? {
        return nil
    }
}

extension JFPopupView: JFPopupAnimationProtocol {
    public func dismiss(with transitonContext: UIViewControllerContextTransitioning?, config: JFPopupConfig, contianerView: UIView?, completion: ((Bool) -> Void)?) {
        JFPopupAnimation.dismiss(with: transitonContext, config: self.config, contianerView: contianerView, completion: completion)
    }

    public func present(with transitonContext: UIViewControllerContextTransitioning?, config: JFPopupConfig, contianerView: UIView, completion: ((Bool) -> Void)?) {
        JFPopupAnimation.present(with: transitonContext, config: self.config, contianerView: contianerView, completion: completion)
    }
}
