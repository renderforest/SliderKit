//
//  ScaledSlider.swift
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

public struct SliderData {
    
    /// Range to be shown in user's side
    public var externalRange: [ClosedRange<Int>]
    
    /// Range that should be used for internal calculations only
    public var internalRange: [ClosedRange<Int>]
    
    /// Slider thumb images for each range
    /// The default value is nil
    public var thumbImages: [ClosedRange<Int>: UIImage]?
    
    public init(
        externalRange: [ClosedRange<Int>],
        internalRange: [ClosedRange<Int>],
        thumbImages: [ClosedRange<Int>: UIImage]? = nil
    ) {
        self.externalRange = externalRange
        self.internalRange = internalRange
        self.thumbImages = thumbImages
    }
}

/// Custom subtype of slider with non-linear behaviour. The whole track layer could be divided
/// into several small parts with it's own density of points
open class ScaledSlider: UISlider {
        
    /// Indicator that shows does `changeValue` function needs to be debounced
    open var debouncesIncrementChanges: Bool = true
    
    /// Debouncing duration. Default value is 0.35
    open var debouncingDuration: Double = 0.35
    var valueUpdateWorkItem: DispatchWorkItem?
    
    /// Slider thumb's position value
    open var externalValue: Int = 0
    
    /// Trackline custom image
    /// Default value is nil
    open var tracklineImage: UIImage? {
        get { minimumTrackImage(for: .normal) }
        set {
            setMinimumTrackImage(newValue, for: .normal)
            setMaximumTrackImage(newValue, for: .normal)
        }
    }
    
    /// Callback function
    open var onValueChanged: ((Int) -> Void)?
    
    /// Callback function
    open var onValueUpdated: ((Int) -> Void)?
    
    /// Initial slider data passed with initializer
    var data: SliderData
    
    public init(data: SliderData) {
        self.data = data
        
        super.init(frame: .zero)
        commonInit()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        maximumValue = 1000
        
        addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        addTarget(self, action: #selector(valueUpdated), for: .touchCancel)
        addTarget(self, action: #selector(valueUpdated), for: .touchUpInside)
        addTarget(self, action: #selector(valueUpdated), for: .touchUpOutside)
        
        check(data: data)
    }
    
    /// Check data to meet conditions written in assert functions
    func check(data: SliderData) {
        
        let externalRangeBounds = data.externalRange.endIndex - data.externalRange.startIndex
        let internalRangeBounds = data.internalRange.endIndex - data.internalRange.startIndex
        
        assert(
            externalRangeBounds == internalRangeBounds,
            "External range should have the same size as internal for appropriate mapping"
        )
        
        let lastValue = data.internalRange.last!.upperBound
        assert(
            lastValue == Int(maximumValue),
            "Slider maximum value should be same as internal range last value"
        )
    }
    
    /// Updates thumb position eather by calling this function or by sliding thumb in trackline.
    /// - Parameter sliderValue: External slider value that should be transformed to internal thumb position
    open func update(sliderValue: Int) {
        externalValue = sliderValue
        
        if let thumbImages = data.thumbImages {
            for (range, image) in thumbImages {
                if range ~= sliderValue {
                    setThumbImage(image, for: .normal)
                    break
                }
            }
        }
        
        for (index, range) in data.externalRange.enumerated() {
            let internalValue = map(
                range: range,
                domain: data.internalRange[index],
                value: externalValue
            )
            
            if internalValue > -1 {
                onValueChanged?(Int(externalValue))
                value = Float(internalValue)
                break
            }
        }
    }
    
    /// Changes thumb's position by given amount of value
    /// - Parameters:
    ///   - amount: Specified amount of points
    open func changeValue(by amount: Int) {
        
        let newValue = value + Float(amount)
        if newValue > minimumValue && newValue < maximumValue {
            update(sliderValue: externalValue + amount)
        }
        
        onValueChanged?(Int(externalValue))
        updateWorkItem()
    }
    
    /// Transformation function that changes internal range to external and vice versa.
    /// - Parameters:
    ///   - range: Range that should be transformed
    ///   - domain: Range into which transformation function should be done
    ///   - value: Current position of thumb in external or internal coordinate system
    /// - Returns: Transformed current position of thumb in external or internal coordinate system
    func map(range: ClosedRange<Int>, domain: ClosedRange<Int>, value: Int) -> Int {
        if range ~= value {
            return domain.lowerBound +
                      (domain.upperBound - domain.lowerBound) *
                      (value - range.lowerBound) /
                      (range.upperBound - range.lowerBound)
        } else {
            return -1
        }
    }
        
    /// Creates `DispatchWorkItem` if it doesn't created yet and debouncing `onValueUpdated` function's calling by given amount of time.
    func updateWorkItem() {
        if debouncesIncrementChanges {
            valueUpdateWorkItem?.cancel()
            valueUpdateWorkItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                
                self.onValueUpdated?(Int(self.externalValue))
            }
            
            DispatchQueue.main.asyncAfter(
                deadline: .now() + debouncingDuration,
                execute: valueUpdateWorkItem!
            )
        } else {
            onValueUpdated?(Int(externalValue))
        }
    }
    
    @objc func valueChanged() {
        for (index, range) in data.internalRange.enumerated() {
            let val = map(
                range: range,
                domain: data.externalRange[index], value: Int(value)
            )
            if val > -1 {
                update(sliderValue: val)
                break
            }
        }
    }
    
    @objc func valueUpdated() {
        onValueUpdated?(Int(externalValue))
    }
}
