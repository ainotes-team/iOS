import SwiftUI


class Plugin : UIView {
    // public static UIBarButtonItem PluginBarButton = 
    
    let pluginId: Int64
    init(frame: CGRect, pluginId: Int64) {
        self.pluginId = pluginId
        
        super.init(frame: frame)
        
        self.pluginInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // abstract functions
    func pluginInit() {
        fatalError("Subclasses need to implement the `pluginInit()` method.")
    }
    
    func getPluginModel() -> PluginModel {
        fatalError("Subclasses need to implement the `getPluginModel()` method.")
    }
}
