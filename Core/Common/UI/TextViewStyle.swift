//
//  TextStyle.swift
//
//
//  Created by MK on 2022/3/24.
//

import UIKit

// MARK: - TextViewStyle

public protocol TextViewStyle {
    var font: UIFont {
        get
    }

    var color: UIColor {
        get
    }

    var textAlignment: NSTextAlignment {
        get
    }

    var backgroundColor: UIColor {
        get
    }
}

public extension TextViewStyle {
    var textAttributes: [NSAttributedString.Key: Any] {
        [NSAttributedString.Key.font: font,
         NSAttributedString.Key.foregroundColor: color]
    }
}

// MARK: - ButtonViewStyle

public protocol ButtonViewStyle: TextViewStyle {
    var highlightedTextColor: UIColor? {
        get
    }

    var highlightedImageColor: UIColor? {
        get
    }

    var highlightedBackgroundColor: UIColor? {
        get
    }

    var disabledColor: UIColor? {
        get
    }
}

public extension TextViewStyle {
    var backgroundColor: UIColor {
        .clear
    }
}

public extension UILabel {
    convenience init(text: String, style: TextViewStyle) {
        self.init()
        self.text = text
        font = style.font
        textColor = style.color
        textAlignment = style.textAlignment
        backgroundColor = style.backgroundColor
        numberOfLines = 0
    }
}

public extension UITextView {
    convenience init(text: String, style: TextViewStyle) {
        self.init()
        self.text = text
        font = style.font
        textColor = style.color
        textAlignment = style.textAlignment
        backgroundColor = style.backgroundColor
    }
}

public extension UIButton {
    convenience init(type: UIButton.ButtonType, style: ButtonViewStyle) {
        self.init(type: type)

        titleLabel?.font = style.font
        setTitleColor(style.color, for: .normal)

        titleLabel?.textAlignment = style.textAlignment
        backgroundColor = style.backgroundColor

        if let color = style.highlightedTextColor {
            setTitleColor(color, for: .highlighted)
        }
        if let btn = self as? YXButton {
            btn.setBackgroundColor(style.highlightedBackgroundColor, for: .highlighted)
            btn.setBackgroundColor(style.backgroundColor, for: .normal)
        }
    }
}

public extension NSAttributedString {
    convenience init(text: String, style: TextViewStyle) {
        self.init(string: text,
                  attributes: [NSAttributedString.Key.font: style.font,
                               NSAttributedString.Key.backgroundColor: style.backgroundColor,
                               NSAttributedString.Key.foregroundColor: style.color])
    }
}

// MARK: - AppViewStyle

public struct AppViewStyle {
    public let font: UIFont
    public let textAlignment: NSTextAlignment

    let colorBuilder: () -> UIColor

    let backgourndColorBuilder: (() -> UIColor)?
    let highlightTextColorBuilder: (() -> UIColor)?
    let highlightImageColorBuilder: (() -> UIColor)?
    let highlightBackgroundColorBuilder: (() -> UIColor)?

    let disabledColorBuilder: (() -> UIColor)?

    public init(font: UIFont,
                textAlignment: NSTextAlignment = .start,
                colorBuilder: @escaping () -> UIColor,
                disabledColorBuilder: (() -> UIColor)? = nil,
                backgourndColorBuilder: (() -> UIColor)? = nil,
                highlightTextColorBuilder: (() -> UIColor)? = nil,
                highlightImageColorBuilder: (() -> UIColor)? = nil,
                highlightBackgroundColorBuilder: (() -> UIColor)? = nil)
    {
        self.font = font
        self.textAlignment = textAlignment
        self.colorBuilder = colorBuilder
        self.disabledColorBuilder = disabledColorBuilder
        self.backgourndColorBuilder = backgourndColorBuilder
        self.highlightBackgroundColorBuilder = highlightBackgroundColorBuilder
        self.highlightImageColorBuilder = highlightImageColorBuilder
        self.highlightTextColorBuilder = highlightTextColorBuilder
    }
}

// MARK: ButtonViewStyle

extension AppViewStyle: ButtonViewStyle {
    public var color: UIColor {
        colorBuilder()
    }

    public var backgroundColor: UIColor {
        backgourndColorBuilder == nil ? .clear : backgourndColorBuilder!()
    }

    public var disabledColor: UIColor? {
        disabledColorBuilder?()
    }

    public var highlightedTextColor: UIColor? {
        highlightTextColorBuilder?()
    }

    public var highlightedImageColor: UIColor? {
        highlightImageColorBuilder?()
    }

    public var highlightedBackgroundColor: UIColor? {
        highlightBackgroundColorBuilder?()
    }
}
