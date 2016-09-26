
import Foundation

open class SuggestibleTextFieldCell: NSTextFieldCell {
    
    
    /* Force NSTextFieldCell to use white as the text color when drawing on a dark background. NSTextField does this by default when the text color is set to black. In the suggestionsprototype.xib, there is an NSTextField that has a blueish text color. In IB we set the cell of that text field to this class to get the drawing behavior we want.
    
    */
    override open func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        let textColor = self.textColor
        
        if self.backgroundStyle == .dark {
            self.textColor = NSColor.white
        }
        
        super.draw(withFrame: cellFrame, in: controlView)
        self.textColor = textColor
    }
}
