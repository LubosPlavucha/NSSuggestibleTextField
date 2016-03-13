
import Foundation

class CleverTextField: NSTextField, NSTextFieldDelegate {
    
    
    var parentViewController: NSViewController!
    private var popoverController: PopoverViewController!
    private var boundObject: AnyObject?
    private var boundKeyPath: String?
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.delegate = self
    }
    
    
    override func bind(binding: String, toObject observable: AnyObject, withKeyPath keyPath: String, var options: [String : AnyObject]?) {
        
        boundObject = observable
        boundKeyPath = keyPath
        
        // make sure the validate immediately option is set to true (if it is set in IB, this doesn't conflict with it)
        options?[NSValidatesImmediatelyBindingOption] = true
        super.bind(binding, toObject: observable, withKeyPath: keyPath, options: options)
    }
    
    
    override func textDidEndEditing(notification: NSNotification) {
       
        // TODO not working
        if boundObject != nil && boundKeyPath != nil {
            
            var value: AnyObject?
            value = self.stringValue
            do {
                try (boundObject as! NSManagedObject).validateValue(&value, forKey: boundKeyPath!)
            } catch {
                
                self.backgroundColor = NSColor(red: 255/255, green: 200/255, blue: 200/255, alpha: 0.7)
                if popoverController == nil {
                    popoverController = PopoverViewController()
                }
                
                parentViewController.presentViewController(popoverController, asPopoverRelativeToRect: NSRect(x: 0,y: 0,width: self.frame.width, height: self.frame.height), ofView: self, preferredEdge: .MaxX, behavior: .ApplicationDefined)
            }
        }
    }
    
    
    class PopoverViewController: NSViewController {
        
        
        var validationText = ""
        
        
        override func loadView() {
            self.view = NSView()
            let textField = NSTextField()
            textField.stringValue = "XXX"
            self.view.addSubview(textField)
        }
    }
}
