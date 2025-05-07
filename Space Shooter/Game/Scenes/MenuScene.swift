import SpriteKit
import SwiftUI

class MenuScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = CGPoint(x: 0.5, y: 0.5) // Center anchor for easier positioning

        setupTitle()
        setupInstructions()
        setupStaticPlayer()
    }

    func setupTitle() {
        let titleLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        titleLabel.text = "Space Shooter"
        titleLabel.fontSize = 60
        titleLabel.fontColor = .cyan
        titleLabel.position = CGPoint(x: 0, y: 150) // Relative to center
        titleLabel.zPosition = Constants.ZPositions.hud
        addChild(titleLabel)
    }

    func setupInstructions() {
        let instructionLabel = SKLabelNode(fontNamed: "HelveticaNeue")
        instructionLabel.text = "Press Enter to Play"
        instructionLabel.fontSize = 30
        instructionLabel.fontColor = .white
        instructionLabel.position = CGPoint(x: 0, y: -50) // Relative to center
        instructionLabel.zPosition = Constants.ZPositions.hud
        addChild(instructionLabel)

        // Optional: Add a blinking effect to the instruction label
        let fadeOut = SKAction.fadeOut(withDuration: 0.7)
        let fadeIn = SKAction.fadeIn(withDuration: 0.7)
        let blinkSequence = SKAction.sequence([fadeOut, fadeIn])
        instructionLabel.run(SKAction.repeatForever(blinkSequence))
    }

    func setupStaticPlayer() {
        // Use the same PlayerNode creation for visual consistency, but it won't be interactive here.
        // Position it to the left of the screen's center.
        let player = PlayerNode.newInstance(size: CGSize(width: 60, height: 60)) // Slightly larger for menu
        player.position = CGPoint(x: 0, y: 50) // Centered above instruction label
        player.physicsBody = nil // Remove physics body for menu scene
        addChild(player)
    }

    override func keyDown(with event: NSEvent) {
        // KeyCode 36 is Return (Enter)
        // KeyCode 76 is Enter on the numeric keypad
        if event.keyCode == 36 || event.keyCode == 76 {
            startGame()
        } else {
            super.keyDown(with: event) // Important for other potential system key events
        }
    }

    func startGame() {
        if let view = self.view {
            // Ensure the size of the GameScene matches the view's bounds
            let gameScene = GameScene(size: view.bounds.size)
            gameScene.scaleMode = self.scaleMode // Or set explicitly, e.g., .resizeFill

            // Add a transition
            let transition = SKTransition.fade(withDuration: 1.0)
            view.presentScene(gameScene, transition: transition)
        }
    }

    // We don't need update or physics interactions in the menu scene
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}

#if DEBUG // Optional: Ensures this code is only compiled for Debug builds
@available(macOS 11.0, *) // SpriteView is available from macOS 11
struct MenuScene_Previews: PreviewProvider {
    static var previews: some View {
        // Create a MenuScene instance
        let menuScene = MenuScene(size: CGSize(width: 800, height: 600)) // Provide a sample size

        // Use SpriteView to host the SKScene
        SpriteView(scene: menuScene)
            .frame(width: 400, height: 300) // Define the preview window size
            .ignoresSafeArea() // Often good for game previews
    }
}
#endif
