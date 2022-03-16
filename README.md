# AnimatingProgressIndicator
 An NSProgressIndicator-like NSView that countsdown and fires a completion block.
 
The idea was that I needed a visual countdown to an event firing. Initially I just used a `Timer` to fire at the specified moment, but I thought it would be more constructive for the user to see a (circular) bar slowly shrinking to zero and then the event happens. 
 
I assumed it would be an easy matter to set up some sort of `CABasicAnimation` on the already existing `NSProgressIndicator` but this proved tricky. Also, it's nice to have as minimal a setup as possible for something like this - I find boilerplate `Timer` or animation code tiresome!!

You can specify which `orientation` (left, right, top, bottom) that the bar animates towards
as well as the starting value (`fromValue`), and the final `toValue` (both are in the range 0...1, where 0 is zero degrees from the top, bottom, left, right as per the `oreientation`, and 1 is 360 degrees around from it).
There is the option to repeat with the `repeats` iVar as well as setting a `completionBlock` which is `()->Void`
which fires each time the bar reaches the `toValue`.
 
The animation works by setting the `needsDisplay` to `true` during the animation process. It's set via an `@objc`
method which is performed after a delay of 0.0 after the `drawRect:` pass. This is a little hack that seems to work:
setting the `needsDisplay` within the `drawRect:` seems to do nothing (presumably because OSX sets it to
`false` directly after it's refreshed the view. Delaying the setting of this flag - even by a non-intuitive 0.0 secs - means that
OSX will respect the value.
 
 
 *Animation cycle:*
 
 * Host class calls the `startAnimation()` function.
 * The `_animationStartTime` is set from `nil` to the current date.
 * The `needsDisplay` is set
 * On the next draw cycle the bar is drawn and if we still need to, we call the delayed setting of the `needsDisplay`
 * If we've drawn and now we don't need to, then call the `completionBlock` (if it exists).
        At this point set the `_animationStartTime` back to `nil` so it isn't called again.
        The decision to animate or not is conditioned by whether the `_animationStartTimea` is `nil` or if longer than the
        animation's `duration` has passed.



In the below example, the `orientation` is set to `top` and the indicator has about two-thirds of the way left to the end of it's animation:

![Example](https://github.com/BrightScreenTV/AnimatingProgressIndicator/blob/main/Screenshot%202022-03-16%20at%2020.52.11.png)
