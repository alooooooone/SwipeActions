<a href="#"><img src="Assets/Header.png" width="400" alt="SwipeActions"></a>

Add customizable swipe actions to any view.

- Enable swipe actions on any view, not just Lists.
- Customize literally everything — corner radius, color, etc...
- Supports drag-to-delete and advanced gesture handling.
- Fine-tune animations and styling to your taste.
- Programmatically show/hide swipe actions.
- Automatically close when interacting with other views.
- SwiftUI views with optional UIKit gesture input. Supports iOS 14+.
- Lightweight, no dependencies.


![General](Assets/General.png) | ![Basics](Assets/Basics.png) | ![Customization](Assets/Customization.png)
| --- | --- | --- |
![Styles](Assets/Styles.png) | ![Animations](Assets/Animations.png) | ![Advanced](Assets/Advanced.png)



### Installation

SwipeActions is available via the [Swift Package Manager](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app). For this local version, use the package or copy all Swift files in [`Sources`](Sources) into your project. Requires iOS 14+; the optional UIKit gesture input requires iOS 18+.

```
https://github.com/aheze/SwipeActions
```

### Usage

```swift
import SwiftUI
import SwipeActions

struct ContentView: View {
    var body: some View {
        SwipeView {
            Text("Hello")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(32)
        } trailingActions: { _ in
            SwipeAction("World") {
                print("Tapped!")
            }
        }
        .padding()
    }
}
```

<img src="Assets/Result.png" width="300" alt="The result, 'World' displayed on the right.">


### Examples

Check out the [example app](https://github.com/aheze/SwipeActions/archive/refs/heads/main.zip) for all examples and advanced usage!

![2 screenshots of the example app](Assets/ExampleApp.png)

### Customization

SwipeActions supports over 20 modifiers for customization. To use them, simply attach the modifier to `SwipeAction`/`SwipeView`.

```swift
SwipeView {
    Text("Hello")
} leadingActions: { _ in
} trailingActions: { _ in
    SwipeAction("World") {
        print("Tapped!")
    }
    .allowSwipeToTrigger() /// Modifiers for `SwipeAction` go here.
}
.swipeActionsStyle(.cascade) /// Modifiers for `SwipeView` go here.
```

```swift
// MARK: - Available modifiers for `SwipeAction` (the side views)

/**
 Apply this to the edge action to enable drag-to-trigger.

     SwipeView {
         Text("Swipe")
     } leadingActions: { _ in
         SwipeAction("1") {}
             .allowSwipeToTrigger()

         SwipeAction("2") {}
     } trailingActions: { _ in
         SwipeAction("3") {}

         SwipeAction("4") {}
             .allowSwipeToTrigger()
     }
 */
func allowSwipeToTrigger(_ value: Bool = true)

/// Constrain the action's content size (helpful for text).
func swipeActionLabelFixedSize(_ value: Bool = true) 

/// Additional horizontal padding.
func swipeActionLabelHorizontalPadding(_ value: Double = 16)

/// The opacity of the swipe actions, determined by `actionsVisibleStartPoint` and `actionsVisibleEndPoint`.
func swipeActionChangeLabelVisibilityOnly(_ value: Bool) 
```

```swift
// MARK: - Available modifiers for `SwipeView` (the main view)

/// The minimum distance needed to drag to start the gesture. Should be more than 0 for best compatibility with other gestures/buttons.
func swipeMinimumDistance(_ value: Double) 

/// The style to use (`mask`, `equalWidths`, or `cascade`).
func swipeActionsStyle(_ value: SwipeActionStyle) 

/// The corner radius that encompasses all actions.
func swipeActionsMaskCornerRadius(_ value: Double) 

/// At what point the actions start becoming visible.
func swipeActionsVisibleStartPoint(_ value: Double) 

/// At what point the actions become fully visible.
func swipeActionsVisibleEndPoint(_ value: Double)

/// The corner radius for each action.
func swipeActionCornerRadius(_ value: Double) 

/// The width for each action.
func swipeActionWidth(_ value: Double) 

/// Spacing between actions and the label view.
func swipeSpacing(_ value: Double) 

/// The point where the user must drag to expand actions.
func swipeReadyToExpandPadding(_ value: Double) 

/// The point where the user must drag to enter the `triggering` state.
func swipeReadyToTriggerPadding(_ value: Double) 

/// Ensure that the user must drag a significant amount to trigger the edge action, even if the actions' total width is small.
func swipeMinimumPointToTrigger(_ value: Double) 

/// Applies if `swipeToTriggerLeadingEdge/swipeToTriggerTrailingEdge` is true.
func swipeEnableTriggerHaptics(_ value: Bool) 

/// Applies if `swipeToTriggerLeadingEdge/swipeToTriggerTrailingEdge` is false, or when there's no actions on one side.
func swipeStretchRubberBandingPower(_ value: Double)

/// If true, you can change from the leading to the trailing actions in one single swipe.
func swipeAllowSingleSwipeAcross(_ value: Bool) 

/// The animation used for adjusting the content's view when it's triggered.
func swipeActionContentTriggerAnimation(_ value: Animation)

/// Values for controlling the close animation.
func swipeOffsetCloseAnimation(stiffness: Double, damping: Double)

/// Values for controlling the expand animation.
func swipeOffsetExpandAnimation(stiffness: Double, damping: Double)

/// Values for controlling the trigger animation.
func swipeOffsetTriggerAnimation(stiffness: Double, damping: Double)
```

Example usage of these modifiers is available in the [example app](https://github.com/aheze/SwipeActions/archive/refs/heads/main.zip).

### Notes

#### Directional UIKit input (local extension)

On iOS 18+, opt in with `.swipeUsesUIKitHorizontalPan()`. The default remains the original SwiftUI input. The UIKit recognizer rejects vertical/diagonal intent before recognition, lets ancestor scroll views take those drags, and locks an accepted drag horizontally. Cancellation closes without triggering an action. The ordinary drag follows the finger without implicit animation; release uses a single CADisplayLink-driven presentation position with the configured springs and a short bounded velocity projection. The row, actions and reveal mask share that position; interrupting a settlement takes over the visible position rather than its target. Resistance starts with a continuous slope, and single trigger-action labels animate continuously toward the dragged edge after crossing the trigger threshold and reverse from their current progress when pulled back.

```swift
SwipeView { /* row */ } leadingActions: { _ in
    SwipeAction("Show") { }
} trailingActions: { _ in
    SwipeAction("Remove") { }.allowSwipeToTrigger()
}
.swipeUsesUIKitHorizontalPan()
.swipeMinimumDistance(8)
.swipeHorizontalIntentRatio(1.5) // Horizontal travel must be > 1.5 × vertical travel.
.swipeStretchRubberBandingPower(0.5)
.swipeOffsetCloseAnimation(stiffness: 90, damping: 20)
.swipeOffsetExpandAnimation(stiffness: 90, damping: 20)
```

For UIKit input, non-triggering actions begin resisting at their expanded width. Triggering actions keep following the finger through the configured trigger threshold. `swipeMinimumDistance` controls horizontal recognition; vertical intent is rejected as early as 4 pt to avoid delaying scroll. Increase the intent ratio to favor scrolling more strongly. `swipeMinimumPointToTrigger` is a separate distance for committing an action, not the recognition threshold. iOS 14–17 retain the SwiftUI input even when opted in.

- To automatically close swipe views when another one is swiped (accordion style), use `SwipeViewGroup`.

```swift
SwipeViewGroup {
    SwipeView {} /// Only one of the actions will be shown.
    SwipeView {}
    SwipeView {}
}
```

- To programmatically show/hide actions, use the `context` parameter.

```swift
import Combine
import SwiftUI
import SwipeActions

struct ProgrammaticSwipeView: View {
    @State var open = PassthroughSubject<Void, Never>()

    var body: some View {
        SwipeView {
            Button {
                open.send() /// Fire the `PassthroughSubject`.
            } label: {
                Text("Tap to Open")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(32)
            }
        } trailingActions: { context in
            SwipeAction("Tap to Close") {
                context.state.wrappedValue = .closed
            }
            .onReceive(open) { _ in /// Receive the `PassthroughSubject`.
                context.state.wrappedValue = .expanded
            }
        }
    }
}
```

- To enable swiping on transparent areas, add `.contentShape(Rectangle())`.

```swift
SwipeView {
    Text("Lots of empty space here.")
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .contentShape(Rectangle()) /// Enable swiping on the empty space.
} trailingActions: { _ in
    SwipeAction("Hello!") { }
}
```

- Everything in the example app is swipeable — even the gray-capsule headers!

<img src="Assets/ExampleAppHeaders.png" width="300" alt="The 'Styles' header swiped to the left and the 'Open' action shown on the right.">


### Community

Author | Contributing | Need Help?
--- | --- | ---
SwipeActions is made by [aheze](https://github.com/aheze). | All contributions are welcome. Just [fork](https://github.com/aheze/SwipeActions/fork) the repo, then make a pull request. | Open an [issue](https://github.com/aheze/SwipeActions/issues) or join the [Discord server](https://discord.com/invite/Pmq8fYcus2). You can also ping me on [Twitter](https://twitter.com/aheze0).

### License

```
MIT License

Copyright (c) 2023 A. Zheng

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

https://user-images.githubusercontent.com/49819455/231671743-baca394e-fc74-4062-83eb-2024b8add924.mp4
