
import Foundation

public class RoundedCornersView: NSView {
    
    
    var rcvCornerRadius: CGFloat!
    override public var flipped: Bool {
        get {
            return true
        }
    }
    
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.rcvCornerRadius = 5.0
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    override public func drawRect(dirtyRect: NSRect) {
        let cornerRadius = self.rcvCornerRadius
        
        let borderPath = NSBezierPath(roundedRect: self.bounds, xRadius:cornerRadius, yRadius: cornerRadius)
        NSColor.windowBackgroundColor().setFill()
        borderPath.fill()
    }
    
}
