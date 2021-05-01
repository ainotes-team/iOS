import Foundation
import SQift

enum FileChangedType {
    case created
    case updated
    case deleted
}

class FileHelper {
    let fileChangedEvent = Event<(FileModel, FileChangedType)>()
    
    let connection: Connection
    let migrator: Migrator
    
    init() {
        let databaseFileName = "database.db3"
        let databaseFilePath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(databaseFileName)"
        
        connection = try! Connection(storageLocation: .onDisk(databaseFilePath))
        migrator = Migrator(connection: connection, desiredSchemaVersion: 1)
        
        try! migrator.runMigrationsIfNecessary(migrationSQLForSchemaVersion: { version in
            print("SQLite Migrator - Current version: \(version)")
            
            let SQL: String = ""
            
            switch version {
            default:
                break
            }
            
            return SQL
        },
        willMigrateToSchemaVersion: { version in
            print("SQLite Migrator - Will migrate to schema version: \(version)")
        },
        didMigrateToSchemaVersion: { version in
            print("SQLite Migrator - Did migrate to schema version: \(version)")
        })
        
        do {
            let fileTableSql: String = """
            CREATE TABLE IF NOT EXISTS FileModels (
                fileId INTEGER PRIMARY KEY AUTOINCREMENT,
                parentDirectoryId INTEGER,
                name TEXT,
                creationDate INTEGER,
                lastChangedDate INTEGER,
                lineMode INTEGER,
                strokeContent TEXT,
                deleted INTEGER,
                zoom REAL,
                scrollX REAL,
                scrollY REAL,
                labelsJson TEXT,
                isFavorite INTEGER,
                isShared INTEGER,
                bookmarksJson TEXT,
                remoteFileId TEXT,
                lastSynced INTEGER
            );
            """
            try connection.execute(fileTableSql)
        } catch {
            print(error)
        }
        
    }
    
    func insertFile(fm: FileModel) -> Int64 {
        let jsonEncoder = JSONEncoder()
        // actual insertion
        let statement: Statement = try! connection.prepare("INSERT INTO FileModels(parentDirectoryId,name,creationDate,lastChangedDate,lineMode,strokeContent,deleted,zoom,scrollX,scrollY,labelsJson,isFavorite,isShared,bookmarksJson,remoteFileId,lastSynced) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)").bind(
            fm.parentDirectoryId,
            fm.name,
            fm.creationDate,
            fm.lastChangedDate,
            fm.lineMode,
            fm.strokeContent,
            fm.deleted,
            fm.zoom,
            fm.scrollX,
            fm.scrollY,
            String(data: jsonEncoder.encode(fm.labels), encoding: .utf8),
            fm.isFavorite,
            fm.isShared,
            String(data: jsonEncoder.encode(fm.bookmarks), encoding: .utf8),
            fm.remoteFileId,
            fm.lastSynced
        ).run()
        print(statement)
        
        let resultId: Int64 = connection.lastInsertRowID
        
        // event invocation
        var tempFm = fm
        tempFm.fileId = resultId
        fileChangedEvent.raise(data: (tempFm, .created))
        
        // return id
        return resultId
    }
    
    func updateFile(fm: FileModel) {
        // actual update
        let statement: Statement = try! connection.prepare("UPDATE FileModels SET strokeContent = ? WHERE fileId = ?").bind(
            fm.strokeContent,
            fm.fileId
        ).run()
        print(statement)
        
        // event invocation
        fileChangedEvent.raise(data: (fm, .updated))
    }
    
    func listFiles() -> [FileModel] {
        let result: [FileModel] = try! connection.query("SELECT * FROM FileModels")
        return result;
    }

    func deleteFile(fm: FileModel) {
        // actual deletion
        let statement: Statement = try! connection.prepare("DELETE FROM FileModels WHERE fileId = ?").bind(
            fm.fileId
        ).run()
        print(statement)
        
        // event invocation
        fileChangedEvent.raise(data: (fm, .deleted))
    }
}
