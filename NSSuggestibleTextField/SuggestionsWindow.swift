
import Foundation


open class SuggestionsWindow: NSWindow {
    
    
    var parentElement: NSView!
    

    
    override init(contentRect: NSRect, styleMask aStyle: NSWindowStyleMask, backing bufferingType: NSBackingStoreType, defer flag: Bool) {
        
        super.init(contentRect: contentRect, styleMask: aStyle, backing: bufferingType, defer: flag)
        
        // This window always has a shadow and is transparent. Force those setting here.
        self.hasShadow = true
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
    }
    
}
