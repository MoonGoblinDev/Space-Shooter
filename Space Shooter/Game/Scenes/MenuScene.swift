// Space Shooter/Game/Scenes/MenuScene.swift
import SpriteKit
import SwiftUI

class MenuScene: SKScene {

    private var backgroundNodes: [SKSpriteNode] = []
    private var individualBackgroundWidth: CGFloat = 0
    private var lastBackgroundUpdateTime: TimeInterval = 0

    private var titleLabelNode: SKLabelNode?
    private var instructionLabelNode: SKLabelNode?
    private var staticPlayerNode: PlayerNode?

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = CGPoint(x: 0.5, y: 0.5)

        setupScrollingBackground()
        setupUIElements()
    }

    func setupScrollingBackground() {
        for node in backgroundNodes {
            node.removeFromParent()
        }
        backgroundNodes.removeAll()

        let backgroundTexture = SKTexture(imageNamed: "Nebula Blue")
        backgroundTexture.filteringMode = .nearest

        let aspectRatio = backgroundTexture.size().width / backgroundTexture.size().height
        let scaledHeight = size.height
        self.individualBackgroundWidth = scaledHeight * aspectRatio
        
        // Use 3 segments for a more robust scrolling experience
        let numberOfSegments = 3

        for i in 0..<numberOfSegments {
            let backgroundNode = SKSpriteNode(texture: backgroundTexture)
            // For anchor (0.5, 0.5), node.position is its center.
            // We position them side-by-side, centered around the scene's origin initially.
            // E.g., for 3 nodes, positions might be -W, 0, W or similar, depending on strategy.
            // The simplest for looping is to lay them out starting from an arbitrary point and let scrolling handle it.
            // The current logic positions node centers at 0*W, 1*W, 2*W relative to the scene's anchor (0,0).
            backgroundNode.position = CGPoint(x: CGFloat(i) * individualBackgroundWidth, y: 0)
            backgroundNode.size = CGSize(width: individualBackgroundWidth, height: scaledHeight)
            backgroundNode.zPosition = Constants.ZPositions.background
            backgroundNodes.append(backgroundNode)
            addChild(backgroundNode)
        }
    }

    func setupUIElements() {
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

        staticPlayerNode = PlayerNode.newInstance(size: CGSize(width: 40, height: 40))
        staticPlayerNode?.physicsBody = nil
        staticPlayerNode?.updateThruster(isMoving: true)
        addChild(staticPlayerNode!)
        
        updateUIPositions()
    }
    
    func updateUIPositions() {
        titleLabelNode?.position = CGPoint(x: 0, y: size.height * 0.25)
        staticPlayerNode?.position = CGPoint(x: 0, y: size.height * 0.05)
        instructionLabelNode?.position = CGPoint(x: 0, y: -size.height * 0.15)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 76 {
            startGame()
        } else {
            super.keyDown(with: event)
        }
    }

    func startGame() {
        guard let view = self.view else { return }
        let gameScene = GameScene(size: view.bounds.size)
        gameScene.scaleMode = self.scaleMode
        let transition = SKTransition.fade(withDuration: 1.0)
        view.presentScene(gameScene, transition: transition)
    }

    override func update(_ currentTime: TimeInterval) {
        if lastBackgroundUpdateTime.isZero {
            lastBackgroundUpdateTime = currentTime
        }
        let deltaTime = currentTime - lastBackgroundUpdateTime
        lastBackgroundUpdateTime = currentTime
        
        let maxDeltaTime: TimeInterval = 1.0 / 30.0
        let cappedDeltaTime = min(deltaTime, maxDeltaTime)

        scrollBackground(deltaTime: cappedDeltaTime)
    }

    func scrollBackground(deltaTime: TimeInterval) {
        guard !backgroundNodes.isEmpty, individualBackgroundWidth > 0 else { return }

        let scrollAmount = Constants.backgroundScrollSpeed * CGFloat(deltaTime)
        let sceneLeftEdge = -size.width / 2
        // This is individualBackgroundWidth * backgroundNodes.count (which is now 3)
        let totalBackgroundWidth = individualBackgroundWidth * CGFloat(backgroundNodes.count)

        for backgroundNode in backgroundNodes {
            backgroundNode.position.x -= scrollAmount

            // Node's position is its center. Its right edge is position.x + individualBackgroundWidth / 2.
            if (backgroundNode.position.x + individualBackgroundWidth / 2) < sceneLeftEdge {
                backgroundNode.position.x += totalBackgroundWidth
            }
        }
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        setupScrollingBackground()
        updateUIPositions()
    }
}

#if DEBUG
@available(macOS 11.0, *)
struct MenuScene_Previews: PreviewProvider {
    static var previews: some View {
        let menuScene = MenuScene(size: CGSize(width: 800, height: 600))
        SpriteView(scene: menuScene)
            .frame(width: 400, height: 300)
            .ignoresSafeArea()
    }
}
#endif
