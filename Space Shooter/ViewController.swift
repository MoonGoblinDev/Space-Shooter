import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Create and configure the MenuScene first.
            // The size is derived from the view's bounds
            let menuScene = MenuScene(size: view.bounds.size)
            menuScene.scaleMode = .resizeFill // Or .aspectFill / .aspectFit as preferred

            // Present the scene.
            view.presentScene(menuScene)
            
            view.ignoresSiblingOrder = true
            
            // For debugging (can be enabled for GameScene specifically if needed):
            // view.showsFPS = true
            // view.showsNodeCount = true
            // view.showsPhysics = true
        }
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        if let skView = self.view as? SKView {
            if let scene = skView.scene {
                // The size of the current scene should always match the view's bounds
                // This is important if the window is resized.
                scene.size = skView.bounds.size
            }
        }
    }
}
