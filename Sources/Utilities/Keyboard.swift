//
//  Keyboard.swift
//  Ello
//
//  Created by Colin Gray on 2/26/2015.
//  Copyright (c) 2015 Ello. All rights reserved.
//

private let sharedKeyboard = Keyboard()

public class Keyboard {
    public struct Notifications {
        public static let KeyboardWillShow = TypedNotification<Keyboard>(name: "com.Ello.Keyboard.KeyboardWillShow")
        public static let KeyboardDidShow = TypedNotification<Keyboard>(name: "com.Ello.Keyboard.KeyboardDidShow")
        public static let KeyboardWillHide = TypedNotification<Keyboard>(name: "com.Ello.Keyboard.KeyboardWillHide")
        public static let KeyboardDidHide = TypedNotification<Keyboard>(name: "com.Ello.Keyboard.KeyboardDidHide")
    }

    public class func shared() -> Keyboard {
        return sharedKeyboard
    }

    public var visible = false
    public var topEdge: CGFloat = 0.0
    public var endFrame = CGRectZero
    public var curve = UIViewAnimationCurve.Linear
    public var options = UIViewAnimationOptions.CurveLinear
    public var duration: Double = 0.0

    public init() {
        let center : NSNotificationCenter = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: Selector("willShow:"), name: UIKeyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: Selector("didShow:"), name: UIKeyboardDidShowNotification, object: nil)
        center.addObserver(self, selector: Selector("willHide:"), name: UIKeyboardWillHideNotification, object: nil)
        center.addObserver(self, selector: Selector("didHide:"), name: UIKeyboardDidHideNotification, object: nil)
    }

    deinit {
        let center : NSNotificationCenter = NSNotificationCenter.defaultCenter()
        center.removeObserver(self)
    }

    public func keyboardTop(#inView: UIView) -> CGFloat {
        let kbdHeight = Keyboard.shared().topEdge
        let window : UIView = inView.window ?? inView
        let bottom = window.convertPoint(CGPoint(x: 0, y: window.bounds.size.height), toView: inView).y
        return bottom - kbdHeight
    }

    @objc
    func willShow(notification : NSNotification) {
        visible = true
        setFromNotification(notification)
        endFrame = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        topEdge = endFrame.size.height

        postNotification(Notifications.KeyboardWillShow, self)
    }

    @objc
    func didShow(notification : NSNotification) {
        postNotification(Notifications.KeyboardDidShow, self)
    }

    @objc
    func willHide(notification : NSNotification) {
        visible = false
        setFromNotification(notification)
        endFrame = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        topEdge = 0

        postNotification(Notifications.KeyboardWillHide, self)
    }

    @objc
    func didHide(notification : NSNotification) {
        postNotification(Notifications.KeyboardDidHide, self)
    }

    private func setFromNotification(notification : NSNotification) {
        if let durationValue = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber {
            duration = durationValue.doubleValue
        }
        else {
            duration = 0
        }
        if let rawCurveValue = (notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber) {
            let rawCurve = rawCurveValue.integerValue
            curve = UIViewAnimationCurve(rawValue: rawCurve) ?? .EaseOut
            let curveInt = UInt(rawCurve << 16)
            options = UIViewAnimationOptions(rawValue: curveInt)
        }
        else {
            curve == .EaseOut
            options = .CurveEaseOut
        }
    }

}
