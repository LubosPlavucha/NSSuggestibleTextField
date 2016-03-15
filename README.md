# NSSuggestibleTextField

Suggestible Text Field component for Cocoa OSX. The user gets the suggestions in the form of the rounded menu as he/she types the text into the text field. The component extends from the NSTextField class. It looks better than the standard NSComboBox.

## How to use it

The suggestible text field is instantiated as any other NSTextField (NSView), either in the Storyboard or programatically. The default implementation is integrated with the Core Data, meaning that the displayed suggestions in the list are the core data **entities**, respectively their attributes. Therefore, you need to define the entity name and the model attribute:

**entityName** - the name of the entity in the core data model <br />
**filterProperty** - the name of the entity attribute to be able to determine, which attribute of the entity to be displayed (the attribute should be of course of the string type) <br />

If you instantiate the component in IB, it is very convenient to define these properties as User Defined Runtime Properties. This way, you can start to use the component in several seconds.

TODO image

#### Non-core data entity list
If you need to have custom suggestions list, which doesn't map one to one to the core data entities, you can do this very easily. You just need to override the following method, which populates the list, and return any objects to be displayed (note: 'filterProperty' for the object still needs to be defined to be able to determine, which attribute of the object to be displayed):

public func getSuggestionsForText(text: String) -> [AnyObject] {

}
