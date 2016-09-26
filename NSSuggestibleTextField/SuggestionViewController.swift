
import Foundation


open class SuggestionViewController: NSViewController {
    
    
    var suggestionKeyPath: String!

    
    func getSuggestionText() -> String? {
        return (self.representedObject as AnyObject).value(forKeyPath: suggestionKeyPath) as? String
    }
}
