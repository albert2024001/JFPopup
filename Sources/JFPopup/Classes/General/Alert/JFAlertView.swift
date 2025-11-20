//
//  JFAlertView.swift
//  JFPopup
//
//  Created by 逸风 on 2021/10/21.
//

import UIKit

public enum JFAlertOption {
    case title(String)
    case titleColor(UIColor)
    case subTitle(String)
    case subTitleColor(UIColor)
    case showCancel(Bool)
    case cancelAction([JFAlertActionOption])
    case confirmAction([JFAlertActionOption])
    case withoutAnimation(Bool)
}

public struct JFAlertConfig {
    var title: String?
    var titleColor: UIColor = .init(red: 20 / 255.0, green: 20 / 255.0, blue: 20 / 255.0, alpha: 1)
    var subTitle: String?
    var subTitleColor: UIColor = .init(red: 94 / 255.0, green: 94 / 255.0, blue: 94 / 255.0, alpha: 1)
    var showCancel = true
    var cancelAction: [JFAlertActionOption]?
    var confirmAction: [JFAlertActionOption]?
    var itemSpacing: CGFloat = 20
    var contentInset = UIEdgeInsets(top: 30, left: 20, bottom: 30, right: 20)
}

class JFAlertView: UIView {
    let margin: CGFloat = 15 * UIScreen.main.scale

    var cancelAction: JFAlertAction?
    var confirmAction: JFAlertAction?

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = self.config.titleColor
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.isHidden = true
        return label
    }()

    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = self.config.subTitleColor
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.isHidden = true
        return label
    }()

    lazy var verStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.titleLabel, self.subTitleLabel])
        stackView.alignment = .center
        stackView.spacing = self.config.itemSpacing
        stackView.axis = .vertical
        stackView.distribution = .fill
        return stackView
    }()

    let bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 221 / 255.0, green: 221 / 255.0, blue: 221 / 255.0, alpha: 1)
        return view
    }()

    var config: JFAlertConfig = .init()
    var clickActionHandle: (() -> Void)?

    public convenience init?(with config: JFAlertConfig) {
        // subTitle or title must have one value
        guard config.subTitle != nil || config.title != nil else {
            return nil
        }
        self.init(frame: .zero)
        self.config = config
        configSubview()
    }

    override init(frame: CGRect) {
        super.init(frame: CGRect(x: CGSize.jf.screenWidth(), y: CGSize.jf.screenHeight(), width: CGSize.jf.screenWidth(), height: CGSize.jf.screenHeight()))
        layer.cornerRadius = 10
        layer.masksToBounds = true
        backgroundColor = .white
    }

    func configAutolayout() {
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomView)
        addConstraints([
            NSLayoutConstraint(item: bottomView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: bottomView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: bottomView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: bottomView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 55),
        ])

        addSubview(verStackView)
        verStackView.translatesAutoresizingMaskIntoConstraints = false
        verStackView.addConstraints([
            NSLayoutConstraint(item: titleLabel, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .width, multiplier: 1, constant: CGSize.jf.screenWidth() - (margin * 2 + config.contentInset.left + config.contentInset.right)),
            NSLayoutConstraint(item: subTitleLabel, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .width, multiplier: 1, constant: CGSize.jf.screenWidth() - (margin * 2 + config.contentInset.left + config.contentInset.right)),
        ])
        addConstraints(
            [
                NSLayoutConstraint(item: verStackView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: verStackView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: -27.5),
            ]
        )
    }

    func configSubview() {
        configAutolayout()
        var cancelAction: [JFAlertActionOption]? = JFAlertActionOption.cancel
        if let cancel = config.cancelAction {
            cancelAction = cancel
        }
        if config.showCancel == false {
            cancelAction = nil
        }
        var arrangedSubviews: [UIView] = []
        if let cancel = cancelAction {
            let action = JFAlertAction(with: cancel, defaultColor: JFAlertCancelColor)
            action.clickBtnCallBack = { [weak self] in
                if let supV = self?.superview as? JFPopupView {
                    supV.dismissPopupView { _ in
                    }
                } else {
                    self?.clickActionHandle?()
                }
            }
            self.cancelAction = action
            if let btn = action.buildActionButton() {
                arrangedSubviews.append(btn)
            }
        }
        if let confirm = config.confirmAction {
            let action = JFAlertAction(with: confirm, defaultColor: JFAlertSureColor)
            action.clickBtnCallBack = { [weak self] in
                if let supV = self?.superview as? JFPopupView {
                    supV.dismissPopupView { _ in
                    }
                } else {
                    self?.clickActionHandle?()
                }
            }
            confirmAction = action
            if let btn = action.buildActionButton() {
                arrangedSubviews.append(btn)
            }
        }

        if arrangedSubviews.count > 0 {
            if let btn1 = arrangedSubviews.first, let btn2 = arrangedSubviews.last {
                let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
                stackView.backgroundColor = .clear
                stackView.alignment = .bottom
                stackView.spacing = 1
                stackView.axis = .horizontal
                stackView.distribution = .fillEqually

                var constraints: [NSLayoutConstraint] = []
                constraints.append(NSLayoutConstraint(item: btn1, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 54))
                if btn1 != btn2 {
                    constraints.append(NSLayoutConstraint(item: btn2, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 54))
                }
                bottomView.addSubview(stackView)
                stackView.translatesAutoresizingMaskIntoConstraints = false
                stackView.addConstraints(constraints)

                addConstraints([
                    NSLayoutConstraint(item: stackView, attribute: .left, relatedBy: .equal, toItem: bottomView, attribute: .left, multiplier: 1, constant: 0),
                    NSLayoutConstraint(item: stackView, attribute: .right, relatedBy: .equal, toItem: bottomView, attribute: .right, multiplier: 1, constant: 0),
                    NSLayoutConstraint(item: stackView, attribute: .bottom, relatedBy: .equal, toItem: bottomView, attribute: .bottom, multiplier: 1, constant: 0),
                    NSLayoutConstraint(item: stackView, attribute: .top, relatedBy: .equal, toItem: bottomView, attribute: .top, multiplier: 1, constant: 1),
                ])
            }
        }

        if let title = config.title {
            titleLabel.text = title
            titleLabel.isHidden = false
        }

        if let subTitle = config.subTitle {
            subTitleLabel.text = subTitle
            subTitleLabel.isHidden = false
        }
        layoutIfNeeded()
        let titleSize = titleLabel.frame.size
        let subTitleSize = subTitleLabel.frame.size
        var height: CGFloat = config.contentInset.bottom + config.contentInset.top
        let width = CGSize.jf.screenWidth() - margin * 2

        if titleSize != .zero {
            height += titleSize.height
        }

        if subTitleSize != .zero {
            height += titleSize != .zero ? config.itemSpacing : 0
            height += subTitleSize.height
        }
        height += 55
        frame = CGRect(x: 0, y: 0, width: width, height: height)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
