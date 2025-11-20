//
//  JFPopupController.swift
//  JFPopup
//
//  Created by 逸风 on 2021/10/9.
//

import UIKit

extension JFPopupController: JFPopupProtocol {
    public func dismissPopupView(completion _: (Bool) -> Void) {
        closeVC(with: nil)
    }

    public func autoDismissHandle() {
        guard config.enableAutoDismiss else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + config.autoDismissDuration.timeDuration()) {
            self.dismissPopupView { _ in
            }
        }
    }
}

open class JFPopupController: UIViewController, JFPopupDataSource {
    // JFPopupProtocol
    public weak var dataSource: JFPopupDataSource?
    public weak var popupProtocol: JFPopupAnimationProtocol?
    public var container: UIView?
    public var config: JFPopupConfig = .dialog
    // JFPopupProtocol

    // JFPopupDataSource
    @objc open func viewForContainer() -> UIView? {
        return nil
    }

    // JFPopupDataSource

    weak var transitionContext: UIViewControllerAnimatedTransitioning?
    var isShow = false
    var beginTouchPoint: CGPoint = .zero
    var beginFrame: CGRect = .zero

    deinit {
        print("JFPopupController dealloc")
    }

    public init(with config: JFPopupConfig) {
        super.init(nibName: nil, bundle: nil)
        transitionContext = self
        self.config = config
    }

    public init(with config: JFPopupConfig, container: (() -> UIView)?) {
        super.init(nibName: nil, bundle: nil)
        self.container = container?()
        transitionContext = self
        self.config = config
    }

    public init(with config: JFPopupConfig, popupProtocol: JFPopupAnimationProtocol? = nil, container: (() -> UIView)?) {
        super.init(nibName: nil, bundle: nil)
        self.popupProtocol = popupProtocol
        self.container = container?()
        transitionContext = self
        self.config = config
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        if popupProtocol == nil {
            popupProtocol = self
        }
        if let container = container {
            view.addSubview(container)
        } else {
            if dataSource == nil {
                dataSource = self
            }
            if let v = dataSource?.viewForContainer() {
                view.addSubview(v)
                container = v
            }
        }
        view.backgroundColor = config.bgColor
        let panGest = UIPanGestureRecognizer(target: self, action: #selector(onPan(gest:)))
        panGest.delegate = self
        view.addGestureRecognizer(panGest)
        let tapGest = UITapGestureRecognizer(target: self, action: #selector(tapBGAction))
        tapGest.delegate = self
        view.addGestureRecognizer(tapGest)
    }

    @objc open func show(with vc: UIViewController) {
        let navi = UINavigationController(rootViewController: self)
        navi.transitioningDelegate = self
        navi.modalPresentationStyle = .custom
        isShow = true
        vc.present(navi, animated: true) {}
    }

    @objc func tapBGAction() {
        guard config.isDismissible else { return }
        closeVC(with: nil)
    }

    @objc open func closeVC(with completion: (() -> Void)?) {
        dismiss(animated: true, completion: completion)
    }

    override open func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        isShow = false
        super.dismiss(animated: flag, completion: completion)
    }

    @objc private func onPan(gest: UIPanGestureRecognizer) {
        guard config.enableDrag else {
            tapBGAction()
            return
        }
        guard let container = container else { return }
        switch gest.state {
        case .began:
            beginFrame = container.frame
            beginTouchPoint = gest.location(in: view)
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
        let currentTouch = pan.location(in: self.view)
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
}

extension JFPopupController: UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
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

    public func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.25
    }

    public func animationController(forDismissed _: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionContext
    }

    public func animationController(forPresented _: UIViewController, presenting _: UIViewController, source _: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return transitionContext
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isShow == true {
            present(transitonContext: transitionContext)
        } else {
            dismiss(transitonContext: transitionContext)
        }
    }

    func present(transitonContext: UIViewControllerContextTransitioning) {
        let toNavi: UINavigationController = transitonContext.viewController(forKey: .to) as! UINavigationController
        let containerView = transitonContext.containerView
        containerView.addSubview(toNavi.view)
        guard let contianerView = container else {
            transitonContext.completeTransition(true)
            return
        }
        popupProtocol?.present(with: transitonContext, config: config, contianerView: contianerView, completion: { [weak self] _ in
            self?.autoDismissHandle()
        })
    }

    func dismiss(transitonContext: UIViewControllerContextTransitioning) {
        popupProtocol?.dismiss(with: transitonContext, config: config, contianerView: container, completion: nil)
    }
}

extension JFPopupController: JFPopupAnimationProtocol {
    public func dismiss(with transitonContext: UIViewControllerContextTransitioning?, config: JFPopupConfig, contianerView: UIView?, completion: ((Bool) -> Void)?) {
        JFPopupAnimation.dismiss(with: transitonContext, config: self.config, contianerView: contianerView, completion: completion)
    }

    public func present(with transitonContext: UIViewControllerContextTransitioning?, config: JFPopupConfig, contianerView: UIView, completion: ((Bool) -> Void)?) {
        JFPopupAnimation.present(with: transitonContext, config: self.config, contianerView: contianerView, completion: completion)
    }
}
