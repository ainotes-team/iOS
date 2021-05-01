import Foundation

struct DirectoryModel {
    // meta data
    let directoryId: Int
    let parentDirectoryId: Int
    let name: String
    
    init(directoryId: Int, parentDirectoryId: Int, name: String) {
        self.directoryId = directoryId
        self.parentDirectoryId = parentDirectoryId
        self.name = name
    }
}
