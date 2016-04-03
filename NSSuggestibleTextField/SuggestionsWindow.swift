
import Foundation


public class SuggestionsWindow: NSWindow {
    
    
    var parentElement: NSView!
    
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(contentRect: NSRect, styleMask aStyle: Int, backing bufferingType: NSBackingStoreType, `defer` flag: Bool) {
        
        super.init(contentRect: contentRect, styleMask: aStyle, backing: bufferingType, defer: flag)
        
        // This window always has a shadow and is transparent. Force those setting here.
        self.hasShadow = true
        self.backgroundColor = NSColor.clearColor()
        self.opaque = false
    }
    
}