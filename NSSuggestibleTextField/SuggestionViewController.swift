
import Foundation


open class SuggestionViewController: NSViewController {
    
    
    var suggestionKeyPath: String!

    
    func getSuggestionText() -> String? {
        if let object = self.representedObject as? NSObject, let value = object.value(forKeyPath: suggestionKeyPath) as? String {
            return value
        }
        return nil
    }
}
