//
//  UIViewSnpConfig.swift
//
//
//  Created by MK on 2022/3/26.
//

import SnapKit
import UIKit

public typealias SnapKitConfigure = (UIView?, SnapKit.ConstraintMaker) -> Void

// MARK: - SnpObject

public protocol SnpLayoutObject: NSObject {
    var snpDSL: ConstraintAttributesDSL {
        get
    }
    func apply(_ config: SnapKitConfigure)

    func makeConstraints(_ closure: (_ make: ConstraintMaker) -> Void)
}

public extension SnpLayoutObject {
    func addSnpConfig(_ config: @escaping SnapKitConfigure) {
        var list = getAssociatedObject(&AssociatedKeys.kSnapConfig) as? NSMutableArray
        if list == nil {
            list = NSMutableArray()
            setAssociatedObject(&AssociatedKeys.kSnapConfig, list)
        }
        list?.add(config)
    }

    func cleanSnpConfigs() {
        var list = getAssociatedObject(&AssociatedKeys.kSnapConfig) as? NSMutableArray
        list?.removeAllObjects()
    }

    func applySnpConfigs() {
        guard let list = getAssociatedObject(&AssociatedKeys.kSnapConfig) as? NSMutableArray else {
            return
        }
        for item in list {
            if let config = item as? SnapKitConfigure {
                apply(config)
            }
        }
    }
}

// MARK: - UIView + SnpObject

extension UIView: SnpLayoutObject {
    public var snpDSL: SnapKit.ConstraintAttributesDSL {
        snp
    }

    public func apply(_ config: SnapKitConfigure) {
        snp.makeConstraints { make in
            config(self.superview, make)
        }
    }

    public func makeConstraints(_ closure: (ConstraintMaker) -> Void) {
        snp.makeConstraints(closure)
    }
}

public extension UIView {
    func addSnpSubview(_ view: UIView) {
        addSubview(view)
        view.applySnpConfigs()
    }

    func addSnpLayoutGuide(_ guide: UILayoutGuide) {
        addLayoutGuide(guide)
        guide.applySnpConfigs()
    }

    func addSnpObject(_ object: SnpLayoutObject) {
        if let view = object as? UIView {
            addSnpSubview(view)
        } else if let guide = object as? UILayoutGuide {
            addSnpLayoutGuide(guide)
        } else {
            print(object.theClassName)
        }
    }
}

// MARK: - UILayoutGuide + SnpObject

extension UILayoutGuide: SnpLayoutObject {
    public var snpDSL: SnapKit.ConstraintAttributesDSL {
        snp
    }

    public func apply(_ config: SnapKitConfigure) {
        snp.makeConstraints {
            config(self.owningView?.superview, $0)
        }
    }

    public func makeConstraints(_ closure: (ConstraintMaker) -> Void) {
        snp.makeConstraints(closure)
    }
}

// MARK: - AssociatedKeys

private enum AssociatedKeys {
    static var kSnapConfig = 0
}