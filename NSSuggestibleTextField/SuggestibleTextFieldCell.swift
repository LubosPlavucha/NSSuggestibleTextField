
import Foundation

public class SuggestibleTextFieldCell: NSTextFieldCell {
    
    
    /* Force NSTextFieldCell to use white as the text color when drawing on a dark background. NSTextField does this by default when the text color is set to black. In the suggestionsprototype.xib, there is an NSTextField that has a blueish text color. In IB we set the cell of that text field to this class to get the drawing behavior we want.
    
    */
    override public func drawWithFrame(cellFrame: NSRect, inView controlView: NSView) {
        
        let textColor = self.textColor
        
        if self.backgroundStyle == .Dark {
            self.textColor = NSColor.whiteColor()
        }
        
        super.drawWithFrame(cellFrame, inView: controlView)
        self.textColor = textColor
    }
}
