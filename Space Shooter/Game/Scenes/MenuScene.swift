import SpriteKit
import SwiftUI

class MenuScene: SKScene {

    private var backgroundNode: SKSpriteNode?

    private var titleLabelNode: SKLabelNode?
    private var instructionLabelNode: SKLabelNode?
    private var staticPlayerNode: PlayerNode?

    private var guideContainerNode: SKNode?
    // --------------------------------------------

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = CGPoint(x: 0.5, y: 0.5)

        setupStaticBackground()
        setupUIElements()
    }

    func setupStaticBackground() {
        backgroundNode?.removeFromParent()

        let backgroundTexture = SKTexture(imageNamed: "Nebula Blue")
        backgroundTexture.filteringMode = .linear

        backgroundNode = SKSpriteNode(texture: backgroundTexture)
        guard let bgNode = backgroundNode else { return }

        let sceneAspectRatio = size.width / size.height
        let textureAspectRatio = backgroundTexture.size().width / backgroundTexture.size().height

        if sceneAspectRatio > textureAspectRatio {
            bgNode.size.width = size.width
            bgNode.size.height = size.width / textureAspectRatio
        } else {
            bgNode.size.height = size.height
            bgNode.size.width = size.height * textureAspectRatio
        }

        bgNode.position = CGPoint.zero
        bgNode.zPosition = Constants.ZPositions.background
        addChild(bgNode)
    }

    // Helper to create icon nodes using SF Symbols
    @available(macOS 11.0, *)
    private func createInstructionIcon(systemSymbolName: String, size: CGSize, color: NSColor = .white) -> SKSpriteNode? {
        guard let image = NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: nil) else {
            print("Failed to load SF Symbol: \(systemSymbolName)")
            return nil
        }
        let tintedImage = image.tinted(with: color)
        
        let texture = SKTexture(image: tintedImage)
        let iconNode = SKSpriteNode(texture: texture, size: size)
        return iconNode
    }

    func setupUIElements() {
        titleLabelNode?.removeFromParent()
        instructionLabelNode?.removeFromParent()
        staticPlayerNode?.removeFromParent()
        guideContainerNode?.removeFromParent()

        // Title
        titleLabelNode = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        titleLabelNode?.text = "Space Shooter"
        titleLabelNode?.fontSize = 60
        titleLabelNode?.fontColor = .cyan
        titleLabelNode?.zPosition = Constants.ZPositions.hud
        addChild(titleLabelNode!)

        // Main Instruction
        instructionLabelNode = SKLabelNode(fontNamed: "HelveticaNeue")
        instructionLabelNode?.text = "Press Enter to Play"
        instructionLabelNode?.fontSize = 30
        instructionLabelNode?.fontColor = .white
        instructionLabelNode?.zPosition = Constants.ZPositions.hud
        let fadeOut = SKAction.fadeOut(withDuration: 0.7)
        let fadeIn = SKAction.fadeIn(withDuration: 0.7)
        instructionLabelNode?.run(SKAction.repeatForever(SKAction.sequence([fadeOut, fadeIn])))
        addChild(instructionLabelNode!)

        // Static Player
        staticPlayerNode = PlayerNode.newInstance(size: CGSize(width: 150, height: 75)) // Adjusted size for menu
        staticPlayerNode?.physicsBody = nil
        staticPlayerNode?.updateThruster(isMoving: true)
        addChild(staticPlayerNode!)
        
        // --- Setup How-to-Play Guide ---
        guideContainerNode = SKNode()
        guideContainerNode?.zPosition = Constants.ZPositions.hud
        let iconSize = CGSize(width: 20, height: 20)
        let guideTextColor = SKColor.lightGray
        let guideLabelFontSize: CGFloat = 16
        let guideTextBoldFontSize: CGFloat = 16
        let horizontalSpacing: CGFloat = 5.0
        let verticalLineSpacing: CGFloat = 8.0
        var currentX: CGFloat
        let line2ContentNode = SKNode()
        currentX = 0
        let spacebarLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        spacebarLabel.text = "SPACEBAR"
        spacebarLabel.fontSize = guideTextBoldFontSize
        spacebarLabel.fontColor = guideTextColor
        spacebarLabel.horizontalAlignmentMode = .left
        spacebarLabel.verticalAlignmentMode = .center
        spacebarLabel.position = CGPoint(x: currentX, y: 0)
        line2ContentNode.addChild(spacebarLabel)
        currentX += spacebarLabel.frame.width + horizontalSpacing / 2
        let shootTextLabel = SKLabelNode(fontNamed: "HelveticaNeue")
        shootTextLabel.text = ": SHOOT"
        shootTextLabel.fontSize = guideLabelFontSize
        shootTextLabel.fontColor = guideTextColor
        shootTextLabel.horizontalAlignmentMode = .left
        shootTextLabel.verticalAlignmentMode = .center
        shootTextLabel.position = CGPoint(x: currentX, y: 0)
        line2ContentNode.addChild(shootTextLabel)
        line2ContentNode.position = CGPoint(x: 0, y: 0)
        guideContainerNode?.addChild(line2ContentNode)
        let line1ContentNode = SKNode()
        currentX = 0

        if #available(macOS 11.0, *) {
            let arrowColor = NSColor.cyan.withAlphaComponent(0.8)
            let icons: [SKSpriteNode?] = [
                createInstructionIcon(systemSymbolName: "arrow.left.circle.fill", size: iconSize, color: arrowColor),
                createInstructionIcon(systemSymbolName: "arrow.up.circle.fill", size: iconSize, color: arrowColor),
                createInstructionIcon(systemSymbolName: "arrow.down.circle.fill", size: iconSize, color: arrowColor),
                createInstructionIcon(systemSymbolName: "arrow.right.circle.fill", size: iconSize, color: arrowColor)
            ]
            for iconNode in icons.compactMap({ $0 }) {
                iconNode.position = CGPoint(x: currentX + iconNode.size.width / 2, y: 0)
                line1ContentNode.addChild(iconNode)
                currentX += iconNode.size.width + horizontalSpacing
            }
        } else {
            // Fallback for older macOS if SF Symbols aren't available/desired
            let arrowKeysLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
            arrowKeysLabel.text = "ARROW KEYS"
            arrowKeysLabel.fontSize = guideTextBoldFontSize
            arrowKeysLabel.fontColor = guideTextColor
            arrowKeysLabel.horizontalAlignmentMode = .left
            arrowKeysLabel.verticalAlignmentMode = .center
            arrowKeysLabel.position = CGPoint(x: currentX, y: 0)
            line1ContentNode.addChild(arrowKeysLabel)
            currentX += arrowKeysLabel.frame.width + horizontalSpacing
        }
        
        let moveTextLabel = SKLabelNode(fontNamed: "HelveticaNeue")
        moveTextLabel.text = ": MOVE"
        moveTextLabel.fontSize = guideLabelFontSize
        moveTextLabel.fontColor = guideTextColor
        moveTextLabel.horizontalAlignmentMode = .left
        moveTextLabel.verticalAlignmentMode = .center
        moveTextLabel.position = CGPoint(x: currentX, y: 0)
        line1ContentNode.addChild(moveTextLabel)
        let line2Height = iconSize.height
        line1ContentNode.position = CGPoint(x: 0, y: line2Height + verticalLineSpacing)
        guideContainerNode?.addChild(line1ContentNode)
        
        if let container = guideContainerNode {
            addChild(container)
        }
        
        updateUIPositions()
    }
    
    func updateUIPositions() {
        // Position Title, Player, Main Instruction (centered elements)
        titleLabelNode?.position = CGPoint(x: 0, y: size.height * 0.25)
        staticPlayerNode?.position = CGPoint(x: 0, y: size.height * 0.05)
        instructionLabelNode?.position = CGPoint(x: 0, y: -size.height * 0.15)

        // Position How-to-Play Guide (bottom-right)
        if let container = guideContainerNode {
            let marginRight: CGFloat = 40
            let marginBottom: CGFloat = 25

            var contentWidth: CGFloat = 0
            var contentHeight: CGFloat = 0

            if let line1 = container.children.first(where: { $0 === container.children.last }),
               let line2 = container.children.first(where: { $0 === container.children.first }) {
                var line1MaxX: CGFloat = 0
                line1.children.forEach { line1MaxX = max(line1MaxX, $0.position.x + $0.frame.width / 2) }
                
                var line2MaxX: CGFloat = 0
                line2.children.forEach { line2MaxX = max(line2MaxX, $0.position.x + $0.frame.width / 2) } 

                contentWidth = max(line1MaxX, line2MaxX)

                let line1HeightApproximation = 10
                contentHeight = line1.position.y + 20
            } else {
                 contentWidth = 200
                 contentHeight = 50
            }

            let containerPosX = self.size.width / 2 - contentWidth - marginRight
            let containerPosY = -self.size.height / 2 + marginBottom
            
            container.position = CGPoint(x: containerPosX, y: containerPosY)
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 76 { // Enter or Return keys
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
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        setupStaticBackground()
        setupUIElements()
    }
}

#if DEBUG
@available(macOS 11.0, *)
struct MenuScene_Previews: PreviewProvider {
    static var previews: some View {
        let menuScene = MenuScene(size: CGSize(width: 800, height: 600))
        // menuScene.scaleMode = .aspectFill
        SpriteView(scene: menuScene)
            .frame(width: 800, height: 600)
            .ignoresSafeArea()
    }
}
#endif
