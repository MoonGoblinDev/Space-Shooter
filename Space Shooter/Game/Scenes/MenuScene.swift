// Space Shooter/Game/Scenes/MenuScene.swift
import SpriteKit
import SwiftUI

class MenuScene: SKScene {

    // private var backgroundNodes: [SKSpriteNode] = [] // No longer an array for scrolling
    // private var individualBackgroundWidth: CGFloat = 0 // Not needed for static
    // private var lastBackgroundUpdateTime: TimeInterval = 0 // Not needed for static
    private var backgroundNode: SKSpriteNode? // Single static background

    private var titleLabelNode: SKLabelNode?
    private var instructionLabelNode: SKLabelNode?
    private var staticPlayerNode: PlayerNode?

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = CGPoint(x: 0.5, y: 0.5) // Center anchor point is good for static UI

        setupStaticBackground() // Changed from setupScrollingBackground
        setupUIElements()
    }

    func setupStaticBackground() {
        backgroundNode?.removeFromParent() // Remove old one if resizing

        let backgroundTexture = SKTexture(imageNamed: "Nebula Blue")
        backgroundTexture.filteringMode = .linear // .linear might look better for static detailed BG

        backgroundNode = SKSpriteNode(texture: backgroundTexture)
        guard let bgNode = backgroundNode else { return }

        // Make the background cover the entire scene, maintaining aspect ratio
        // This is "aspect fill" behavior for the background
        let sceneAspectRatio = size.width / size.height
        let textureAspectRatio = backgroundTexture.size().width / backgroundTexture.size().height

        if sceneAspectRatio > textureAspectRatio {
            // Scene is wider than texture: fit to width, height will be larger
            bgNode.size.width = size.width
            bgNode.size.height = size.width / textureAspectRatio
        } else {
            // Scene is taller than texture (or same aspect ratio): fit to height, width will be larger
            bgNode.size.height = size.height
            bgNode.size.width = size.height * textureAspectRatio
        }

        bgNode.position = CGPoint.zero // Center the background since anchorPoint is (0.5, 0.5)
        bgNode.zPosition = Constants.ZPositions.background
        addChild(bgNode)
    }

    func setupUIElements() {
        // ... (no changes to this method)
        titleLabelNode?.removeFromParent()
        instructionLabelNode?.removeFromParent()
        staticPlayerNode?.removeFromParent()

        titleLabelNode = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        titleLabelNode?.text = "Space Shooter"
        titleLabelNode?.fontSize = 60
        titleLabelNode?.fontColor = .cyan
        titleLabelNode?.zPosition = Constants.ZPositions.hud
        addChild(titleLabelNode!)

        instructionLabelNode = SKLabelNode(fontNamed: "HelveticaNeue")
        instructionLabelNode?.text = "Press Enter to Play"
        instructionLabelNode?.fontSize = 30
        instructionLabelNode?.fontColor = .white
        instructionLabelNode?.zPosition = Constants.ZPositions.hud
        let fadeOut = SKAction.fadeOut(withDuration: 0.7)
        let fadeIn = SKAction.fadeIn(withDuration: 0.7)
        instructionLabelNode?.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))
        addChild(instructionLabelNode!)

        staticPlayerNode = PlayerNode.newInstance(size: CGSize(width: 40, height: 40)) // Original size
        staticPlayerNode?.physicsBody = nil // No physics needed on menu screen
        staticPlayerNode?.updateThruster(isMoving: true) // Keep thruster effect
        addChild(staticPlayerNode!)
        
        updateUIPositions()
    }
    
    func updateUIPositions() {
        // ... (no changes to this method)
        titleLabelNode?.position = CGPoint(x: 0, y: size.height * 0.25)
        staticPlayerNode?.position = CGPoint(x: 0, y: size.height * 0.05)
        instructionLabelNode?.position = CGPoint(x: 0, y: -size.height * 0.15)
    }

    override func keyDown(with event: NSEvent) {
        // ... (no changes to this method)
        if event.keyCode == 36 || event.keyCode == 76 { // Enter or Return keys
            startGame()
        } else {
            super.keyDown(with: event)
        }
    }

    func startGame() {
        // ... (no changes to this method)
        guard let view = self.view else { return }
        let gameScene = GameScene(size: view.bounds.size)
        gameScene.scaleMode = self.scaleMode // Ensure scaleMode is consistent
        let transition = SKTransition.fade(withDuration: 1.0)
        view.presentScene(gameScene, transition: transition)
    }

    // REMOVED: override func update(_ currentTime: TimeInterval)
    // REMOVED: func scrollBackground(deltaTime: TimeInterval)
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        setupStaticBackground() // Re-setup the static background on resize
        updateUIPositions()   // Re-position UI elements
    }
}

#if DEBUG
@available(macOS 11.0, *)
struct MenuScene_Previews: PreviewProvider {
    static var previews: some View {
        let menuScene = MenuScene(size: CGSize(width: 800, height: 600))
        // menuScene.scaleMode = .aspectFill // Set if needed for preview consistency
        SpriteView(scene: menuScene)
            .frame(width: 400, height: 300) // Adjust preview frame size as needed
            .ignoresSafeArea()
    }
}
#endif
