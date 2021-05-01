import UIKit

class FileManagerViewController: UITableViewController {
    var detailViewController: EditorViewController? = nil
    var fileModels = [FileModel]()

    override init(style: UITableView.Style) {
        super.init(style: style)
        postInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        postInit()
    }
    
    func postInit() {
        SceneDelegate.fileHelper.fileChangedEvent.addHandler(handler: fileChangedHandler)
    }
    
    func fileChangedHandler(fileModel: FileModel, changeType: FileChangedType) {
        print(fileModel, changeType)
        switch changeType {
        case .created:
            print("add fm to list")

            fileModels.insert(fileModel, at: 0)
            let indexPath = IndexPath(row: 0, section: 0)
            tableView.insertRows(at: [indexPath], with: .automatic)
            break
        case .updated:
            // TODO: Actual update instead of replace
            let idx = fileModels.firstIndex(where: {$0.fileId == fileModel.fileId})
            if ((idx) != nil) {
                let indexPath = IndexPath(row: idx!, section: 0)
                fileModels.remove(at: idx!)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            fileModels.insert(fileModel, at: idx!)
            let indexPath = IndexPath(row: idx!, section: 0)
            tableView.insertRows(at: [indexPath], with: .none)
            break
        case .deleted:
            let idx = fileModels.firstIndex(where: {$0.fileId == fileModel.fileId})
            if ((idx) != nil) {
                let indexPath = IndexPath(row: idx!, section: 0)
                fileModels.remove(at: idx!)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            // TODO
            break
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // load files
        self.fileModels = (SceneDelegate.fileHelper.listFiles())
        
        // set toolbar items
        navigationItem.leftBarButtonItem = editButtonItem
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
    }
    
    @objc
    func insertNewObject(_ sender: Any) {
        let alert = UIAlertController(title: "Datei erstellen", message: "Bitte gib einen Dateinamen an", preferredStyle: .alert)
        
        // Ok button
        let okAction = UIAlertAction(title: "Erstellen", style: .default, handler: { (action) -> Void in
            let fileNameTxt = alert.textFields![0]
            
            let fm = FileModel(fileId: 0, parentDirectoryId: 0, name: fileNameTxt.text ?? "Unbenannt")
            let _ = SceneDelegate.fileHelper.insertFile(fm: fm)
        })

        // Cancel button
        let cancelAction = UIAlertAction(title: "Abbrechen", style: .destructive, handler: { (action) -> Void in })

        // file name entry
        alert.addTextField { (textField: UITextField) in
            textField.placeholder = "Dateiname"
            textField.keyboardType = .default
            textField.isSelected = true
        }

        // Add actions
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        // show
        self.present(alert, animated: true, completion: nil)

    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepare", segue.identifier ?? "null", tableView.indexPathForSelectedRow ?? "null", segue.destination)
        if segue.identifier == "openFile" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = fileModels[indexPath.row]
                let controller = segue.destination as! EditorViewController
                controller.fileModel = object
                detailViewController = controller
                
                tableView.deselectRow(at: indexPath, animated: false)
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileModels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let fm = fileModels[indexPath.row]
        cell.textLabel!.text = fm.name
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            SceneDelegate.fileHelper.deleteFile(fm: fileModels[indexPath.row])
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
}

