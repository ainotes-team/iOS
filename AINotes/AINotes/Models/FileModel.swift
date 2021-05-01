import Foundation
import SQift

struct FileModel {
    // meta data
    var fileId: Int64
    var parentDirectoryId: Int64
    var name: String
    
    let creationDate: UInt64
    let lastChangedDate: UInt64
    
    // content
    let lineMode: Int
    
    var strokeContent: String?
    
    // state
    let deleted: Bool
    
    // scroller
    let zoom: Float
    let scrollX: Float
    let scrollY: Float
    
    // file badges
    let labels: [Int]
    
    let isFavorite: Bool
    let isShared: Bool
    
    // file bookmarks
    let bookmarks: [FileBookmarkModel]
    
    // cloud sync
    let remoteFileId: String?
    let lastSynced: UInt64?
    
    init(fileId: Int64, parentDirectoryId: Int64, name: String) {
        self.fileId = fileId
        self.parentDirectoryId = parentDirectoryId
        self.name = name
        self.creationDate = 0
        self.lastChangedDate = 0
        self.lineMode = 0
        self.strokeContent = nil
        self.deleted = false
        self.zoom = 1.0
        self.scrollX = 0
        self.scrollY = 0
        self.labels = []
        self.isFavorite = false
        self.isShared = false
        self.bookmarks = []
        self.remoteFileId = nil
        self.lastSynced = nil
    }
}

extension FileModel: ExpressibleByRow {
    init(row: Row) throws {
        guard
            let fileId: Int64 = row[0],
            let parentDirectoryId: Int64 = row[1],
            let name: String = row[2],
            let creationDate: UInt64 = row[3],
            let lastChangedDate: UInt64 = row[4],
            let lineMode: Int = row[5],
            let strokeContent: String? = row[6],
            let deleted: Bool = row[7],
            let zoom: Float = row[8],
            let scrollX: Float = row[9],
            let scrollY: Float = row[10],
            let labelsJson: String = row[11],
            let isFavorite: Bool = row[12],
            let isShared: Bool = row[13],
            let bookmarksJson: String = row[14],
            let remoteFileId: String? = row[15],
            let lastSynced: UInt64? = row[16]
        else {
            throw ExpressibleByRowError(type: FileModel.self, row: row)
        }
        
        let jsonDecoder = JSONDecoder()
        
        self.fileId = fileId
        self.parentDirectoryId = parentDirectoryId
        self.name = name
        self.creationDate = creationDate
        self.lastChangedDate = lastChangedDate
        self.lineMode = lineMode
        self.strokeContent = strokeContent
        self.deleted = deleted
        self.zoom = zoom
        self.scrollX = scrollX
        self.scrollY = scrollY
        self.labels = try jsonDecoder.decode([Int].self, from: labelsJson.data(using: .utf8)!)
        self.isFavorite = isFavorite
        self.isShared = isShared
        self.bookmarks = try jsonDecoder.decode([FileBookmarkModel].self, from: bookmarksJson.data(using: .utf8)!)
        self.remoteFileId = remoteFileId
        self.lastSynced = lastSynced
    }
}
