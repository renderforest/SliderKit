# Installation

SliderKit is available through [Swift Package Manager](https://www.swift.org/package-manager/)

# Usage 

### Initializing
```swift
let data = SliderData(
    externalRange: [
        50...79,
        80...120,
        121...200
    ],
    internalRange: [
        0...199,
        200...800,
        801...1000
    ],
    thumbImages: [
        50...64: UIImage(named: "red_thumb")!,
        65...79: UIImage(named: "orange_thumb")!,
        80...120: UIImage(named: "blue_thumb")!,
        121...159: UIImage(named: "orange_thumb")!,
        160...200: UIImage(named: "red_thumb")!
    ]
)
var slider = ScaledSlider(data: data)
slider.tracklineImage = UIImage(named: "track_layer")
slider.debouncesIncrementChanges = true
slider.debouncingDuration = 0.45
```

### Updating slider value
```swift
slider.update(sliderValue: value)
```

#### OR
```swift
slider.changeValue(by: 5)
```

### Callback listeners
```swift
slider.onValueChanged = { value in
  print(value)
}
        
slider.onValueUpdated = { value in
  print(value)
}
```
# License
SliderKit is available under the MIT license. See the LICENSE file for more information.
