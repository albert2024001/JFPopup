//
//  JFToastView.swift
//  JFPopup
//
//  Created by 逸风 on 2021/10/16.
//

import UIKit

// only loading style have queue
private var JFLoadingViewsQueue: [JFToastQueueTask] = []

public enum JFToastOption {
    case hit(String)
    case icon(JFToastAssetIconType)
    case enableAutoDismiss(Bool)
    case enableUserInteraction(Bool)
    case autoDismissDuration(JFTimerDuration)
    case bgColor(UIColor)
    case mainContainer(UIView)
    case withoutAnimation(Bool)
    case position(JFToastPosition)
    case enableRotation(Bool)
    case contentInset(UIEdgeInsets)
    case itemSpacing(CGFloat)
}

public enum JFToastAssetIconType {
    case success
    case fail
    case imageName(name: String, imageType: String = "png")

    func getImageName() -> (name: String, imageType: String)? {
        switch self {
        case .success:
            return ("success", "png")
        case .fail:
            return ("fail", "png")
        case let .imageName(name: name, imageType: imageType):
            return (name, imageType)
        }
    }
}

public struct JFToastConfig {
    var title: String?
    var assetIcon: JFToastAssetIconType?
    var enableDynamicIsLand: Bool = false
    var enableRotation: Bool = false
    var contentInset: UIEdgeInsets = .init(top: 12, left: 25, bottom: 12, right: 25)
    var itemSpacing: CGFloat = 5.0
}

public class JFToastView: UIView {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 15)
        label.isHidden = true
        return label
    }()

    let iconImgView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    lazy var verStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.iconImgView, self.titleLabel])
        stackView.alignment = .center
        stackView.spacing = self.config.itemSpacing
        stackView.axis = .vertical
        stackView.distribution = .fill
        return stackView
    }()

    var config: JFToastConfig = .init()

    public convenience init?(with config: JFToastConfig) {
        // assetIcon or title must have one value
        guard config.assetIcon != nil || config.title != nil else {
            return nil
        }
        self.init(frame: .zero)
        self.config = config
        configSubview()
    }

    override init(frame: CGRect) {
        super.init(frame: CGRect(x: CGSize.jf.screenWidth(), y: CGSize.jf.screenHeight(), width: CGSize.jf.screenWidth(), height: CGSize.jf.screenHeight()))
        backgroundColor = .black
        layer.cornerRadius = config.enableDynamicIsLand ? 17 : 10
    }

    func configSubview() {
        addSubview(verStackView)
        verStackView.translatesAutoresizingMaskIntoConstraints = false
        verStackView.addConstraints([
            NSLayoutConstraint(item: titleLabel, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .width, multiplier: 1, constant: CGSize.jf.screenWidth() - 30 - config.contentInset.left - config.contentInset.right),
        ])
        addConstraints(
            [
                NSLayoutConstraint(item: verStackView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: verStackView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: config.enableDynamicIsLand ? 34 / 2 : 0),
            ]
        )
        if let title = config.title {
            titleLabel.text = title
            titleLabel.isHidden = false
        }

        if let assetIconType = config.assetIcon, let result = assetIconType.getImageName(), let image = getBundleImage(with: result.name, imageType: result.imageType) {
            iconImgView.image = image
            iconImgView.isHidden = false
        }

        layoutIfNeeded()
        let titleSize = titleLabel.frame.size
        let iconSize = iconImgView.frame.size
        var height: CGFloat = config.contentInset.bottom + config.contentInset.top + (config.enableDynamicIsLand ? 34 : 0)
        let horInset = CGFloat(config.contentInset.left + config.contentInset.right)
        let dynamicisLandSize = 120.0 + 20.0 + (iconSize == .zero ? 20 : 0)
        var contentWidth = max(titleSize.width, iconSize.width)
        if iconSize.width > 0 && iconSize.width + horInset > titleSize.width {
            contentWidth = iconSize.width
        }
        var width = contentWidth + horInset

        if titleSize != .zero {
            height += titleSize.height
            if config.enableDynamicIsLand {
                layer.cornerRadius = height / 2
            }
        }

        if iconSize != .zero {
            height += titleSize != .zero ? config.itemSpacing : 0
            height += iconSize.height
            if titleSize == .zero {
                width = height
            }
            if config.enableDynamicIsLand {
                layer.cornerRadius = 20
            }
        }
        if config.enableDynamicIsLand {
            width = max(width, dynamicisLandSize)
        }
        frame = CGRect(x: 0, y: 0, width: width, height: height)
        if config.enableRotation {
            addRotationAnimation()
        }
    }

    func addRotationAnimation() {
        if iconImgView.layer.animationKeys() == nil {
            let baseAni = CABasicAnimation(keyPath: "transform.rotation.z")
            let toValue: CGFloat = .pi * 2.0
            baseAni.toValue = toValue
            baseAni.duration = 1.0
            baseAni.isCumulative = true
            baseAni.repeatCount = MAXFLOAT
            baseAni.isRemovedOnCompletion = false
            iconImgView.layer.add(baseAni, forKey: "rotationAnimation")
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getBundleImage(with imageName: String, imageType: String = "png") -> UIImage? {
        if let img = UIImage(named: imageName) {
            return img
        }
        if let path = Bundle.main.path(forResource: imageName, ofType: imageType), let image = UIImage(contentsOfFile: path) {
            return image
        }
        // support SPM
        if let bundlePath = Bundle.main.path(forResource: "JFPopup_JFPopup", ofType: "bundle") {
            if let imgPath = Bundle(path: bundlePath)?.path(forResource: imageName + "@2x", ofType: imageType), let image = UIImage(contentsOfFile: imgPath) {
                return image
            }
            return nil
        }
        guard let frameWorkPath = Bundle.main.path(forResource: "Frameworks", ofType: nil)?.appending("/JFPopup.framework") else { return nil }
        guard let bundlePath = Bundle(path: frameWorkPath)?.path(forResource: "JFPopup", ofType: "bundle") else { return nil }
        if let imgPath = Bundle(path: bundlePath)?.path(forResource: imageName + "@2x", ofType: imageType), let image = UIImage(contentsOfFile: imgPath) {
            return image
        }
        return nil
    }
}

public extension JFPopup where Base: JFPopupView {
    static func hideLoading() {
        let work = DispatchWorkItem {
            let firstTask = JFLoadingViewsQueue.first
            if firstTask != nil {
                JFLoadingViewsQueue.removeFirst()
            }
            if let v = firstTask?.popupView {
                v.dismissPopupView { _ in }
            }
        }

        if Thread.current == Thread.main {
            work.perform()
        } else {
            DispatchQueue.main.sync(execute: work)
        }
    }

    static func loading() {
        loading(hit: nil)
    }

    static func loading(hit: String?) {
        loading(hit: hit, inView: nil)
    }

    /// show loading view
    /// - Parameters:
    ///   - hit: message
    ///   - inView: only support keywindow or ontroller.view, default keywindow
    static func loading(hit: String?, inView: UIView?) {
        var options: [JFToastOption] = [
            .enableAutoDismiss(false),
            .icon(.imageName(name: "jf_loading")),
            .enableRotation(true),
            .itemSpacing(15),
        ]
        options += [.enableUserInteraction(true)]
        if let view = inView, !JFIsSupportDynamicIsLand {
            options += [.mainContainer(view)]
        }
        if let hit = hit {
            options += [.hit(hit)]
            options += [.contentInset(.init(top: 30, left: 47, bottom: 30, right: 47))]
        } else {
            options += [.contentInset(.init(top: 35, left: 35, bottom: 35, right: 35))]
        }
        JFPopupView.popup.toast { options }
    }

    static func toast(hit: String) {
        toast {
            [.hit(hit)]
        }
    }

    static func toast(hit: String, icon: JFToastAssetIconType) {
        toast {
            [.hit(hit), .icon(icon)]
        }
    }

    @discardableResult static func toast(options: () -> [JFToastOption]) -> JFPopupView? {
        let allOptions = options()
        var mainView: UIView?
        var config: JFPopupConfig = .dialog
        var toastConfig = JFToastConfig()
        config.bgColor = .clear
        config.enableUserInteraction = false
        config.enableAutoDismiss = true
        config.isDismissible = false
        toastConfig.enableDynamicIsLand = config.toastPosition == .dynamicIsland
        for option in allOptions {
            switch option {
            case let .hit(hit):
                toastConfig.title = hit
            case let .icon(icon):
                toastConfig.assetIcon = icon
            case let .enableUserInteraction(enable):
                config.enableUserInteraction = enable
            case let .enableAutoDismiss(autoDismiss):
                config.enableAutoDismiss = autoDismiss
            case let .autoDismissDuration(duration):
                config.autoDismissDuration = duration
            case let .bgColor(bgColor):
                config.bgColor = bgColor
            case let .mainContainer(view):
                mainView = view
            case let .withoutAnimation(without):
                config.withoutAnimation = without
            case let .position(pos):
                config.toastPosition = pos
                toastConfig.enableDynamicIsLand = config.toastPosition == .dynamicIsland && JFIsSupportDynamicIsLand
            case let .enableRotation(enable):
                toastConfig.enableRotation = enable
            case let .contentInset(inset):
                toastConfig.contentInset = inset
            case let .itemSpacing(spcaing):
                toastConfig.itemSpacing = spcaing
            }
        }

        guard toastConfig.title != nil || toastConfig.assetIcon != nil else {
            assert(toastConfig.title != nil || toastConfig.assetIcon != nil, "title or assetIcon only can one value nil")
            return nil
        }
        guard JFLoadingViewsQueue.count == 0 else {
            print("only can show single loading need manual dismiss) view in the same time")
            return nil
        }
        let popupView = custom(with: config, yourView: mainView) { _ in
            JFToastView(with: toastConfig)
        }
        if config.enableAutoDismiss == false {
            Self.safeAppendToastTask(task: JFToastQueueTask(with: config, toastConfig: toastConfig, mainContainer: mainView, popupView: popupView))
        }
        return popupView
    }

    private static func safeAppendToastTask(task: JFToastQueueTask) {
        let work = DispatchWorkItem {
            JFLoadingViewsQueue.append(task)
        }
        if Thread.current == Thread.main {
            work.perform()
        } else {
            DispatchQueue.main.sync(execute: work)
        }
    }
}
