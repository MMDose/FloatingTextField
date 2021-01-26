//
//  MATextField.swift
//  Management App
//
//  Created by Dose on 9/3/20.
//  Copyright © 2020 Doseh. All rights reserved.
//

import UIKit

/// Editable fields states.
///
///  By this cases `TextView` or `TextField` will animate its content.
///
enum FloatingTextFieldStates {
    /// Case that field text is empty.
    ///
    /// Set field state to its default case. Clear text, animate label. Resign from first Responder.
    ///
    case empty
    /// Case that field text should begin editing,
    ///
    /// Show keyboard animate label and more...
    ///
    case editing
    /// Case that field did end editiing.
    ///
    /// Check text state(empty or not) and animate the fiell. if field state is empty it will resign to default state.
    ///
    case end
  
}


final class FloatingTextField: UITextField {
    
    @IBInspectable var pointerY: CGFloat = 3
    
    override func caretRect(for position: UITextPosition) -> CGRect {
        var rect = super.caretRect(for: position)
        rect.size.height = 18
        rect.origin.y = pointerY
        return rect
    }
}

final class FloatingTextFieldView: UIView {
    
    // Protocol requirements.
    
    static var animatable: Bool = true
    static var keyboardAppearInteraction: Bool = true
    
    var didBecomeFirstResponder: (()->())? = nil 
    
    var parentView: UIView { return self}
        
    
    //MARK: @IBOutlets & @IBInspectables -
    
    @IBInspectable var handleKeyboardActions: Bool = true
    
    @IBInspectable var text: String? = "" {
        didSet {
            titleLabel.text = text
        }
    }
    
    @IBInspectable var placeholder: String = "" {
        didSet {
            textField.placeholder = placeholder
        }
    }
    
    @IBInspectable var securityType: Bool = false {
        didSet {
            textField.isSecureTextEntry = securityType
        }
    }
    
    @IBInspectable var showButtonEnabled: Bool = false {
        didSet {
            updateShowButton()
        }
    }
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var textField: FloatingTextField!
    @IBOutlet private weak var titleBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var textFieldHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var textFieldBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var errorMessageLabel: UILabel!
    @IBOutlet private weak var errorLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var errorLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var fieldView: UIView!
    @IBOutlet private weak var showButton: UIButton!
    @IBOutlet private weak var showLeadingTextFieldTrailingConstraint: NSLayoutConstraint!
    
    @IBInspectable var defaultTitleColor: UIColor = #colorLiteral(red: 0.3215686275, green: 0.3568627451, blue: 0.4, alpha: 1)
    @IBInspectable var titleColor: UIColor = #colorLiteral(red: 0.5843137255, green: 0.6117647059, blue: 0.6549019608, alpha: 1)
    
    //MARK: Properties -
    
    weak var delegate: UITextFieldDelegate?
    var didChangeFieldValue: ((String)->())?
    var didTappInView: (()->(Bool))?
    var prefetchUpdateCompletionWhenTextSetManually: Bool = true
    var isErrorShown: Bool = false
    /// Set text for field, turns off keyboard interactions.
    var fieldText: String {
        get {
            return textField.text ?? ""
        }
        set {
            FloatingTextFieldView.keyboardAppearInteraction = false
            setFieldState(state: .editing)
            textField.text = newValue
            if prefetchUpdateCompletionWhenTextSetManually {
                didChangeFieldValue?(newValue)
            }
            setFieldState(state: .end)
            FloatingTextFieldView.keyboardAppearInteraction = true
        }
    }
    
    var fieldTextAttributed: NSAttributedString? {
        get {
            return textField.attributedText
        }
        
        set {
            setFieldState(state: .editing)
            textField.attributedText = newValue
            if let unwrapped = newValue {
                didChangeFieldValue?(unwrapped.string)
            }
            setFieldState(state: .end)
        }
    }
    

    var keyboardType: UIKeyboardType {
        get {
            return .default
        }
        
        set {
            textField.keyboardType = newValue
        }
    }
    
    var textContentType: UITextContentType? {
        get {
            return .nickname
        }
        
        set {
            textField.textContentType = newValue
        }
    }
    
    
    //MARK: Initialization -
    
    override init(frame: CGRect = .init(x: 0, y: 0, width: 328, height: 56)) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    
    //MARK: - Private functions
    
    private func commonInit() {
        loadFromNib()
        setupTextField()
        updateShowButton()
    }
    
    private func setupTextField() {
        textField.delegate = self
        fieldView.layer.masksToBounds = true
        UIView.setAnimationsEnabled(false)
        setFieldState(state: .empty)
        UIView.setAnimationsEnabled(true)
        
    }
    
    private func setFieldState(state: FloatingTextFieldStates) {
        switch state {
        
        case .empty:
            titleTopConstraint.constant = 17
            titleBottomConstraint.constant = 15
            textFieldBottomConstraint.constant = 0
            textFieldHeightConstraint.constant = 0
            setNeedsLayout()
            titleLabel.scale(fontSize: 16, duration: 0.3, animateAnchorPoint: LabelAnimateAnchorPoint.centerXCenterY)
            self.titleLabel.textColor = defaultTitleColor
            animationClosure(animatable: FloatingTextFieldView.animatable, duration: 0.3) {
                self.superview?.layoutIfNeeded()
                self.layoutIfNeeded()
            }
            
        case .editing:
            if FloatingTextFieldView.keyboardAppearInteraction {
                self.textField.becomeFirstResponder()
                didBecomeFirstResponder?() 
            }
            
            titleTopConstraint.constant = 12
            titleBottomConstraint.constant = 0
            textFieldBottomConstraint.constant = 7
            textFieldHeightConstraint.constant = 24
            setNeedsLayout()
            self.superview?.setNeedsLayout()
            titleLabel.scale(fontSize: 12, duration: 0.3, animateAnchorPoint: LabelAnimateAnchorPoint.centerXCenterY)
            self.titleLabel.textColor = titleColor
            animationClosure(animatable: FloatingTextFieldView.animatable, duration: 0.3) {
                self.superview?.layoutIfNeeded()
                self.layoutIfNeeded()
            }            
        case .end:
            textField.endEditing(true)
            if textField.text?.isEmpty ?? true {
                setFieldState(state: .empty)
            }
        }
    }
    
    private func updateShowButton() {
        if showButtonEnabled {
            showButton.isHidden = false
            showLeadingTextFieldTrailingConstraint.priority = UILayoutPriority(rawValue: 999)
        } else {
            showButton.isHidden = true
            showLeadingTextFieldTrailingConstraint.priority = UILayoutPriority(rawValue: 997)
        }
    }
    
    
    //MARK: - Public functions
    
    func showErrorMessage(with message: String) {
        isErrorShown = true
        errorMessageLabel.text = message
        errorLabelTopConstraint.constant = 3
        errorLabelHeightConstraint.constant = 15
        setNeedsLayout()
        self.superview?.setNeedsLayout()
        animationClosure(animatable: true, duration: 0.3) {
            self.superview?.layoutIfNeeded()
            self.layoutIfNeeded()
            self.errorMessageLabel.alpha = 1
            self.fieldView.layer.borderWidth = 1
            self.fieldView.layer.borderColor = UIColor.red.cgColor

        }
    }
    
    func hideCurrentErrorMessage() {
        isErrorShown = false
        errorLabelTopConstraint.constant = 0
        errorLabelHeightConstraint.constant = 0
        setNeedsLayout()
        self.superview?.setNeedsLayout()
        animationClosure(animatable: true, duration: 0.3) {
            self.superview?.layoutIfNeeded()
            self.layoutIfNeeded()
            self.errorMessageLabel.alpha = 0
            self.fieldView.layer.borderWidth = 0
            self.fieldView.layer.borderColor = UIColor.clear.cgColor
        }
      
    }
    
    func startTyping() {
        setFieldState(state: .editing)
    }
    
    func endTyping() {
        setFieldState(state: .end)
    }
    
    func clear() {
        textField.attributedText = nil
        textField.text = ""
        setFieldState(state: .end)
    }
    
    
    //MARK: - IBActions
    
    @IBAction func didChangeFieldValue(_ sender: Any) {
        didChangeFieldValue?(fieldText)
    }
    
    @IBAction func showTapped() {
        textField.isSecureTextEntry = !textField.isSecureTextEntry
    }
    
    @IBAction func didTappInView(_ sender: Any) {
        if let closure = didTappInView {
            if closure() {
                setFieldState(state: .editing)
            } 
        } else {
            setFieldState(state: .editing)
        }
    }
}



//MARK: - UITextFieldDelegate

extension FloatingTextFieldView: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        setFieldState(state: .end)
        return  delegate?.textFieldShouldReturn?(textField) ?? true
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        setFieldState(state: .end)
        delegate?.textFieldDidEndEditing?(textField, reason: reason)
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return delegate?.textFieldShouldBeginEditing?(textField) ?? true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        setFieldState(state: .end)
        return delegate?.textFieldShouldEndEditing?(textField) ?? true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.textFieldDidEndEditing?(textField)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.textFieldDidBeginEditing?(textField)
    }
    
    @available(iOS 13.0, *)
    func textFieldDidChangeSelection(_ textField: UITextField) {
        delegate?.textFieldDidChangeSelection?(textField)
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return delegate?.textFieldShouldClear?(textField) ?? true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return delegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) ?? true
    }
    
}

extension UIView {
    
    @discardableResult
    func loadFromNib<T : UIView>() -> T? {
        guard let contentView = Bundle(for: type(of: self)).loadNibNamed(String(describing: self.classForCoder), owner: self, options: nil)?.first as? T else {
            // xib not loaded, or its top view is of the wrong type
            return nil
        }
        addSubviewSizedConstraints(view: contentView)
        return contentView
    }
    
    @discardableResult
    func loadViewsFromNib<T : UIView>() -> [T]? {
        guard let contentView = Bundle(for: type(of: self)).loadNibNamed(String(describing: self.classForCoder), owner: self, options: nil) as? [T] else {
            // xib not loaded, or its top view is of the wrong type
            return nil
        }
        return contentView
    }
    
    static func loadViewFromNib(named: String, owner: Any?, bundle: Bundle = .main) -> [UIView]? {
        return bundle.loadNibNamed(named, owner: owner, options: nil) as? [UIView]
    }
        
    func addSubviewSizedConstraints(view: UIView, atIndex: Int? = nil) {
        
        if let index = atIndex {
            insertSubview(view, at: index)
        } else {
            addSubview(view)
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        view.setNeedsLayout()
        
        
    }
}

private func animationClosure(animatable: Bool, duration: TimeInterval, delay: TimeInterval = 0.0, animationOption: UIView.AnimationOptions = .curveEaseInOut, _ animation: @escaping ()->(), completion: ((Bool) -> ())? = nil) {
    if animatable {
        UIView.animate(withDuration: duration, delay: delay, options: animationOption, animations: animation, completion: completion)
    } else {
        animation()
    }
}
