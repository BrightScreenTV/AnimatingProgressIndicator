//
//  BTVAnimatingProgressIndicator.swift
//  QuickSlide
//
//  Created by Todd Dalton on 13/03/2022.
//

import Cocoa

/**
 This is a class to animate a circular progress bar - akin to the `NSProgressIndicator`.
 
 You can specify which `orientation` (left, right, top, bottom) that the bar animates towards
 as well as the starting value `fromValue` and the final, `toValue` both (normalised, 0...1).
 There is the option to repeat with the `repeats` iVar as well as setting a `completionBlock` which is `()->Void`
 which fires each time the bar reaches the `toValue`.
 
 The animation works by setting the `needsDisplay` to `true` during the animation process. It's set via an `@objc`
 method which is performed after a delay of 0.0 after the `drawRect:` pass. This is a little hack that seems to work:
 setting the `needsDisplay` within the `drawRect:` function seems to do nothing (presumably because OSX sets it to
 `false` directly after it's refreshed the view. Delaying the setting - even by a non-intuitive 0.0 secs - means that
 it actually remains `true` for the next draw cycle.
 
 
 *Animation cycle:*
 
 User calls the `startAnimation()` function.
 * The `_animationStartTime` is set from `nil` to the current date.
 * The `needsDisplay` is set
 * On the next draw cycle the bar is drawn and if we still need to, we call the delayed setting of the `needsDisplay`
 * If we've drawn and now we don't need to, then call the `completionBlock` (if it exists).
        At this point set the `_animationStartTime` back to `nil` so it isn't called again.
        The decision to animate or not is conditioned by whether the `_animationStartTimea` is `nil` or if longer than the
        animation's `duration` has passed.

 - Parameters:
  - _animationStartTime: An optional to specify when the animation started. `nil` if no animation.
  - toValue: `CGFLoat` to specify where the bar should end up (0...1, or 0 to 360 degrees from orientation)
  - fromValue: `CGFLoat` to specify where the bar should start from (0...1, or 0 to 360 degrees from orientation)
  - orientation: `OrientationDescription` to specify where the zero point is on the circle.
  - repeats: `Bool` to specify whether animation restarts.
  - duration: `TimeInterval` specifying how long animation takes
 
 */
class BTVAnimatingProgressIndicator: NSView {
    
    /// Describes where on the indicator the zero mark is
    enum OrientationDescription {
        case top
        case bottom
        case left
        case right
    }

    /// This is where the progress indicator will animate to (0 - 1)
    var toValue: CGFloat = 0.0
    
    var repeats: Bool = false
    
    /// This is where the progress indicator will start animating (0 - 1)
    var fromValue: CGFloat = 1.0
    
    /// This is the zero position or orientation  of the indicator
    var orientation: OrientationDescription = .top
    
    /// This is the start angle (degress) of the arc to be draw (also where the animation ends up)
    var toAngle: CGFloat {
        return zeroAngle + (360 * toValue)
    }
    
    /// This is where the finish angle (degrees) is, note it is the angle representing the start of the animation when `fromValue = 1.0`
    var fromAngle: CGFloat {
        return zeroAngle - (360 * (fromValue *  (1.0 - _progress)))
    }
    
    /// We need to know where a zero point is, i.e. where the angle would be if everything was zerp
    private var zeroAngle: CGFloat {
        switch orientation {
        case .bottom:
            return 270
        case .top:
            return 90
        case .left:
            return 180
        case .right:
            return 0
        }
    }
    
    /// The duration of the animation in seconds
    @IBInspectable var duration: TimeInterval = 6.0
    
    /// This block (if != nil) will be executed when the bar reaches zero
    var completionBlock:(() -> Void)? = nil
    
    /// This is the current value of the prograss bar to draw
    private var _currentValue: CGFloat {
        guard let _ = _animationStartTime else { return toValue }
        
        let endDelta: CGFloat = toValue - fromValue
        let direction: CGFloat = endDelta / abs(endDelta)
        let valueProgress: CGFloat = _progress / abs(endDelta)
        
        return fromValue + (direction * valueProgress)
    }
    
    ///This is the progress (0 - 1) of the animation
    private var _progress: CGFloat {
        guard let _started = _animationStartTime else { return 0.0 }
        return min(-1 * _started.timeIntervalSinceNow, duration) / duration
    }
    
    ///This is the delta of change of the `currentValue`
    private var _delta: CGFloat {
        return abs(fromValue - toValue) / CGFloat(duration)
    }
    
    /// This is the time the animation was started and is used to calculate the next value
    private var _animationStartTime: Date? = nil
    
    /// A flag to show that we're animating. Set to `false` to pause animation
    var isAnimating: Bool {
        guard let _start = _animationStartTime else { return false }
        return abs(_start.timeIntervalSinceNow) < duration
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        needsDisplay = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        perform(#selector(redisplay), with: nil, afterDelay: 0.0)
    }
    
    override func viewDidMoveToWindow() {
        perform(#selector(redisplay), with: nil, afterDelay: 0.0)
    }
    
    ///Starts the animation afresh
    func startAnimation() {
        if isAnimating { return }
        _animationStartTime = Date()
        needsDisplay = true
    }
    
    /// This is only called when we're animating
    @objc func redisplay() {
        
        // Don't go any further if we're not animating
        guard let _ = _animationStartTime else {
            needsLayout = false
            needsDisplay = false
            return
        }

        // We reach here is there is an animation start time but still need
        // to double-check that we need to animate
        needsLayout = isAnimating
        needsDisplay = isAnimating
        
        // It's possible to get here but have finished the animation, in which case fire completion
        // block and/or repeat if necessary.
        if !isAnimating {
            completionBlock?()
            _animationStartTime = nil
            if repeats { startAnimation() }
        }
    }
    
    /// This can be called to halt the animation but the completion block isn't fired
    func stopAnimating() {
        _animationStartTime = nil
    }
    
    /// This is called at the end of the cycle an restarts it if `repeats`
    @objc private func _endOfAnimationCycle() {
        
        _animationStartTime = nil
        
        completionBlock?()
        
        if repeats {
            startAnimation()
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        NSColor.clear.set()
        dirtyRect.fill()
        
        let arc = NSBezierPath()
        let centre: NSPoint = NSPoint(x: dirtyRect.midX, y: dirtyRect.midY)

        arc.appendArc(withCenter: centre, radius: (min(dirtyRect.width, dirtyRect.height) / 2) * 0.8, startAngle: toAngle, endAngle: fromAngle, clockwise: true)
        arc.lineWidth = 10.0
        arc.lineCapStyle = .round
        NSColor(calibratedRed: 0.000, green: 0.275, blue: 0.286, alpha: 1.00).set()
        arc.stroke()
        
        perform(#selector(redisplay), with: nil, afterDelay: 0.0)
    }
    
}
