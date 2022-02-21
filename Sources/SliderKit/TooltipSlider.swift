//
//  TooltipSlider.swift
//
//  MIT License
//
//  Copyright (c) 2022 Tigran Gishyan
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit

public struct TooltipData {
    public var image: UIImage
    public var label: UILabel
}

/// Custom subtype of slider with tooltip view
open class TooltipSlider: UISlider {

    var tooltipView: TooltipView?
    var onValueChanged: ((Double) -> Void)?
    
    public init() {
        
        super.init(frame: .zero)
        initToolTip()
        
        addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        addTarget(self, action: #selector(thumbHitted), for: .touchDown)
        addTarget(
            self,
            action: #selector(valueCancelled),
            for: [.touchCancel, .touchUpInside, .touchUpOutside]
        )
        
        tooltipView?.callback = { [weak self] val in
            self?.onValueChanged?(val)
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func set(data: TooltipData) {
        tooltipView?.set(data: data)
    }
    
    open func update(tooltipValue: Float) {
        tooltipView?.update(value: tooltipValue)
    }
    
    override open func thumbRect(
        forBounds bounds: CGRect,
        trackRect rect: CGRect,
        value: Float
    ) -> CGRect {
        
        let thumbRect = super.thumbRect(
            forBounds: bounds, trackRect: rect, value: value
        )
        
        let transformedRect = CGRect(
            origin: thumbRect.origin,
            size: CGSize(
                width: thumbRect.width + 18,
                height: 38
            )
        )
        
        let tooltipRect = transformedRect.offsetBy(dx: -9, dy: -(thumbRect.size.height + 6))
        tooltipView?.frame = tooltipRect
        tooltipView?.update(value: self.value)
        
        return thumbRect
    }
    
    func initToolTip() {
        tooltipView = TooltipView()
        tooltipView?.backgroundColor = UIColor.clear
        self.addSubview(tooltipView!)
        tooltipView?.alpha = 0
    }
    
    func changeTooltipWIthAnimation(_ alpha: CGFloat) {
        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                self.tooltipView?.alpha = alpha
            },
            completion: nil
        )
    }
    
    @objc func thumbHitted() {
        changeTooltipWIthAnimation(1)
    }
    
    @objc func valueChanged() {
        update(tooltipValue: value)
    }
    
    @objc func valueCancelled() {
        changeTooltipWIthAnimation(0)
    }
}

open class TooltipView: UIView {
    
    lazy var tooltipLabel = UILabel()
    var callback: ((Double) -> Void)?
    
    let numberFormatter: NumberFormatter = {
        let numberForamtter = NumberFormatter()
        numberForamtter.maximumFractionDigits = 2
        return numberForamtter
    }()
    
    public init() {
        super.init(frame: .zero)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(data: TooltipData) {
        let tooltipImageView = UIImageView()
        tooltipImageView.image = data.image
        
        addSubview(tooltipImageView)
        
        tooltipImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                tooltipImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
                tooltipImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
                tooltipImageView.topAnchor.constraint(equalTo: topAnchor),
                tooltipImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ]
        )
        
        tooltipLabel = data.label
        tooltipImageView.addSubview(tooltipLabel)
        
        tooltipLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                tooltipLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
                tooltipLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
                tooltipLabel.topAnchor.constraint(equalTo: topAnchor),
                tooltipLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
            ]
        )
    }
    
    func update(value: Float) {
        let value: Double = Double(value)
        callback?(value)
        let formattedText = numberFormatter.string(
            from: .init(value: value)
        ) ?? ""
        tooltipLabel.text = formattedText + "x"
        self.setNeedsDisplay()
    }
}
