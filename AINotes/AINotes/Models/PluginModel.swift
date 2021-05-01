struct PluginModel {
    // meta data
    var pluginId: Int64
    var fileId: Int64
    
    init(plugin: Plugin, fileId: Int64) {
        self.pluginId = plugin.pluginId
        self.fileId = fileId
    }
}
