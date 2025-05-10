import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            let menuScene = MenuScene(size: view.bounds.size)
            menuScene.scaleMode = .resizeFill

            // Present the scene.
            view.presentScene(menuScene)
            
            view.ignoresSiblingOrder = true
            
            // For debugging:
            // view.showsFPS = true
            // view.showsNodeCount = true
            // view.showsPhysics = true
        }
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        if let skView = self.view as? SKView {
            if let scene = skView.scene {
                scene.size = skView.bounds.size
            }
        }
    }
}
