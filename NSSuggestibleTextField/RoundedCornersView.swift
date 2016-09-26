
import Foundation

open class RoundedCornersView: NSView {
    
    
    var rcvCornerRadius: CGFloat!
    override open var isFlipped: Bool {
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
    
    
    override open func draw(_ dirtyRect: NSRect) {
        let cornerRadius = self.rcvCornerRadius
        
        let borderPath = NSBezierPath(roundedRect: self.bounds, xRadius:cornerRadius!, yRadius: cornerRadius!)
        NSColor.windowBackgroundColor.setFill()
        borderPath.fill()
    }
    
}
