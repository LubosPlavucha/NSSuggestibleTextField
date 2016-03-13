
import Foundation

public class HighlightingView: NSView {
    
    
    var highlighted: Bool = false {
        didSet {
            if self.highlighted != oldValue {
                // Inform each contained text field what type of background they will be displayed on. This is how the txt field knows when to draw white text instead of black text.
                for subview in self.subviews where subview is NSTextField {
                    (subview as! NSTextField).cell?.backgroundStyle = highlighted ? .Dark : .Light
                }
                self.needsDisplay = true // make sure we redraw with the correct highlight style.
            }
        }
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    
    override public func drawRect(dirtyRect: NSRect) {
        
        if highlighted == true {
            NSColor.alternateSelectedControlColor().set()
            NSRectFillUsingOperation(dirtyRect, .CompositeSourceOver)
        } else {
            NSColor.clearColor().set()
            NSRectFillUsingOperation(dirtyRect, .CompositeSourceOver)
        }
    }
    
}
