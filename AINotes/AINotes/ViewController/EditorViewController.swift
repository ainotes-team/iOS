import UIKit
import MaLiang

class EditorViewController: UIViewController {
    @IBOutlet weak var brushSelection: UISegmentedControl!
    @IBOutlet weak var sizeSlider: UISlider!
    
    @IBOutlet weak var canvas: ScrollableCanvas!
    
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0

    func registerBrushes() {
        do {
            let pen = canvas.defaultBrush!
            pen.name = "Pen"
            pen.opacity = 0.1
            pen.pointSize = 5
            pen.pointStep = 0.5
            pen.forceSensitive = 0.3
            pen.color = color
            
            let pencil = try registerBrush(with: "pencil")
            pencil.rotation = .random
            pencil.pointSize = 3
            pencil.pointStep = 2
            pencil.forceSensitive = 0.3
            pencil.opacity = 1
            
            let brush = try registerBrush(with: "brush")
            brush.rotation = .ahead
            brush.pointSize = 15
            brush.pointStep = 2
            brush.forceSensitive = 1
            brush.color = color
            brush.forceOnTap = 0.5
            
            let texture = try canvas.makeTexture(with: UIImage(named: "glow")!.pngData()!)
            let glow: GlowingBrush = try canvas.registerBrush(name: "glow", textureID: texture.id)
            glow.opacity = 0.05
            glow.coreProportion = 0.2
            glow.pointSize = 20
            glow.rotation = .ahead
            
            let claw = try registerBrush(with: "claw")
            claw.rotation = .ahead
            claw.pointSize = 30
            claw.pointStep = 5
            claw.forceSensitive = 0.1
            claw.color = color
            
            // make eraser with a texture for claw
//            let eraser = try canvas.registerBrush(name: "Eraser", textureID: claw.textureID) as Eraser
//            eraser.rotation = .ahead
            
            /// make eraser with default round point
            let eraser = try! canvas.registerBrush(name: "Eraser") as Eraser
            
            brushes = [pen, pencil, brush, glow, claw, eraser]
            
        } catch MLError.simulatorUnsupported {
            let alert = UIAlertController(title: "Attension", message: "You are running MaLiang on a Simulator, whitch is not supported by Metal. So painting is not alvaliable now. But you can go on testing your other businesses which are not relative with MaLiang. Or you can also runs MaLiang on your Mac with Catalyst enabled now.", preferredStyle: .alert)
//                alert.addAction(title: "确定", style: .cancel)
            self.present(alert, animated: true, completion: nil)
        } catch {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
//                alert.addAction(title: "确定", style: .cancel)
            self.present(alert, animated: true, completion: nil)
        }
        
        brushSelection.removeAllSegments()
        for i in 0 ..< brushes.count {
            let name = brushes[i].name
            brushSelection.insertSegment(withTitle: name, at: i, animated: false)
        }
        
        if brushes.count > 0 {
            brushSelection.selectedSegmentIndex = 0
            styleChanged(brushSelection)
        }
    }
    
    @IBAction func changeSizeAction(_ sender: UISlider) {
        let size = Int(sender.value)
        canvas.currentBrush.pointSize = CGFloat(size)
    }
    
    @IBAction func styleChanged(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        let brush = brushes[index]
        brush.color = color
        brush.use()
        sizeSlider.value = Float(brush.pointSize)
    }
    
    var brushes: [Brush] = []
    var chartlets: [MLTexture] = []
    
    var color: UIColor {
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
    
    private func registerBrush(with imageName: String) throws -> Brush {
        let texture = try canvas.makeTexture(with: UIImage(named: imageName)!.pngData()!)
        return try canvas.registerBrush(name: imageName, textureID: texture.id)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular, scale: .medium)), landscapeImagePhone: UIImage(named: "arrow.left"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(dummySelector(_:))),
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(dummySelector(_:))),
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(dummySelector(_:))),
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(saveAction(_:))),
        ]

        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular, scale: .medium)),
                            landscapeImagePhone: UIImage(named: "arrow.left"),
                            style: .plain,
                            target: self,
                            action: #selector(goBack(_:))
            ),
            
            UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular, scale: .medium)),
                            landscapeImagePhone: UIImage(named: "arrow.left"),
                            style: .plain,
                            target: self,
                            action: #selector(undoAction(_:))
            ),
            
            UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular, scale: .medium)),
                            landscapeImagePhone: UIImage(named: "arrow.left"),
                            style: .plain,
                            target: self,
                            action: #selector(redoAction(_:))
            ),
        ]
        
        canvas.isPencilMode = true
        canvas.data.addObserver(self)
        canvas.addObserver(self)
        registerBrushes()
        loadFile()
    }

    @objc
    func goBack(_ sender: Any) {
        saveAction(sender)
        navigationController!.popViewController(animated: true)
    }
    
    
    @objc
    func dummySelector(_ sender: Any) {
    }

    var fileModel: FileModel? {
        didSet {
            navigationItem.title = fileModel?.name ?? "Unnamed"
            if (canvas != nil) {
                print("fileModel set => loadFile")
                loadFile()
            }
        }
    }
    
    @IBAction func undoAction(_ sender: Any) {
        canvas.undo()
    }
    
    @IBAction func redoAction(_ sender: Any) {
        canvas.redo()
    }
    
    func loadFile() {
        print("loadFile")
        if (fileModel == nil) {
            print("fileModel == nil")
            return;
        }
        let contentData = fileModel!.strokeContent
        if (contentData == nil) {
            print("contentData == nil")
            return;
        }
        print(contentData)
        let content = try! JSONDecoder().decode(CanvasContent.self, from: contentData!.data(using: .utf8)!)
        if let scrollable = canvas as? ScrollableCanvas, let size = content.size {
            scrollable.contentSize = size
        }
        print("loading")
        
        /// import elements to canvas
        content.lineStrips.forEach { $0.brush = canvas.findBrushBy(name: $0.brushName) ?? canvas.defaultBrush }
        content.chartlets.forEach { $0.canvas = canvas }
        canvas.data.elements = (content.lineStrips + content.chartlets).sorted(by: { $0.index < $1.index})
        
        DispatchQueue.main.async {
            /// redraw must be call on main thread
            self.canvas.redraw()
        }
    }
    
    @IBAction func saveAction(_ sender: Any) {
        let data = canvas.data
        let content = CanvasContent(size: canvas.size,
                                lineStrips: data?.elements.compactMap { $0 as? LineStrip } ?? [],
                                chartlets: data?.elements.compactMap { $0 as? Chartlet } ?? [])
        
        let contentData = try! JSONEncoder().encode(content)
        let contentDataJson = String(data: contentData, encoding: .utf8)!
        print(contentDataJson)
        
        self.fileModel!.strokeContent = contentDataJson
        SceneDelegate.fileHelper.updateFile(fm: self.fileModel!)
    }
}


extension EditorViewController: DataObserver {
    // element started
    func lineStrip(_ strip: LineStrip, didBeginOn data: CanvasData) {
        print("lineStrip", strip, data)
    }
    
    // element finished
    func element(_ element: CanvasElement, didFinishOn data: CanvasData) {
        print("element", element, data)
    }
    
    // clear
    func dataDidClear(_ data: CanvasData) {
        print("dataDidClear", data)
        
    }
    
    // undo
    func dataDidUndo(_ data: CanvasData) {
        print("dataDidUndo", data)
        
    }
    
    // redo
    func dataDidRedo(_ data: CanvasData) {
        print("dataDidRedo", data)
        
    }
}

extension EditorViewController: ActionObserver {
    // render events
    func canvas(_ canvas: Canvas, didRenderTapAt point: CGPoint) {
        print("didRenderTapAt", point)
    }
    
    func canvas(_ canvas: Canvas, didRenderChartlet chartlet: Chartlet) {
        print("didRenderChartlet")
    }
    
    // line events
    func canvas(_ canvas: Canvas, didBeginLineAt point: CGPoint, force: CGFloat) {
        print("didBeginLineAt", point, force)
    }
    
    func canvas(_ canvas: Canvas, didMoveLineTo point: CGPoint, force: CGFloat) {
        print("didMoveLineTo", point, force)
    }
    
    func canvas(_ canvas: Canvas, didFinishLineAt point: CGPoint, force: CGFloat) {
        print("didFinishLineAt", point, force)
    }

    // redraw events
    func canvas(_ canvas: Canvas, didRedrawOn target: RenderTarget) {
        print("didRedrawOn")
    }
    
    // scroll / zoom events
    func canvas(_ canvas: ScrollableCanvas, didZoomTo zoomLevel: CGFloat) {
        print("didZoomTo", zoomLevel)
    }

    func canvasDidScroll(_ canvas: ScrollableCanvas) {
        print("canvasDidScroll", canvas.contentOffset)
    }
}
