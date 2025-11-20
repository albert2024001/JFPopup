//
//  JFAlertView+UIViewController.swift
//  JFPopup
//
//  Created by 逸风 on 2021/10/22.
//

import UIKit

public extension JFPopup where Base: UIViewController {
    func alert(options: () -> [JFAlertOption]) {
        let allOptions = options()
        var config: JFPopupConfig = .dialog
        var alertConfig = JFAlertConfig()
        config.enableUserInteraction = true
        config.enableAutoDismiss = false
        config.isDismissible = false
        for option in allOptions {
            switch option {
            case let .title(string):
                alertConfig.title = string
            case let .titleColor(uIColor):
                alertConfig.titleColor = uIColor
            case let .subTitle(string):
                alertConfig.subTitle = string
            case let .subTitleColor(uIColor):
                alertConfig.subTitleColor = uIColor
            case let .showCancel(bool):
                alertConfig.showCancel = bool
            case let .cancelAction(actions):
                alertConfig.cancelAction = actions
            case let .confirmAction(actions):
                alertConfig.confirmAction = actions
            case let .withoutAnimation(bool):
                config.withoutAnimation = bool
            }
        }
        guard alertConfig.title != nil || alertConfig.subTitle != nil else {
            assert(alertConfig.title != nil || alertConfig.subTitle != nil, "title or subTitle only can one value nil")
            return
        }
        guard let alertView = JFAlertView(with: alertConfig) else { return }
        alertView.clickActionHandle = {
            dismissPopup()
        }
        dialog(with: false, bgColor: config.bgColor) {
            alertView
        }
    }
}
