import SpriteKit

class GameOverScene: SKScene {

    var finalScore: Int = 0
    private var backgroundNode: SKSpriteNode?
    private var gameOverTitleNode: SKLabelNode?
    private var scoreLabelNode: SKLabelNode?
    private var backButtonNode: SKLabelNode?

    private var contentReadyToShow = false

    private let uiAppearanceDelay: TimeInterval = 1.0

    init(size: CGSize, score: Int) {
        self.finalScore = score
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        backgroundColor = .black
        anchorPoint = CGPoint(x: 0.5, y: 0.5)

        setupBackground()
        // Create all UI elements initially hidden or transparent
        setupGameOverTitle(visible: false)
        setupScoreLabel(visible: false)
        setupBackButton(visible: false)

        let waitAction = SKAction.wait(forDuration: uiAppearanceDelay)
        let showContentAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.contentReadyToShow = true
            
            // Make all elements visible and animate them in
            self.gameOverTitleNode?.isHidden = false
            self.scoreLabelNode?.isHidden = false
            self.backButtonNode?.isHidden = false
            
            let fadeInDuration = 0.5
            self.gameOverTitleNode?.run(SKAction.fadeIn(withDuration: fadeInDuration))
            self.scoreLabelNode?.run(SKAction.fadeIn(withDuration: fadeInDuration))
            self.backButtonNode?.run(SKAction.fadeIn(withDuration: fadeInDuration))
        }
        
        self.run(SKAction.sequence([waitAction, showContentAction]))
    }

    func setupBackground() {
        let gateTexture = SKTexture(imageNamed: "Gate") 
        backgroundNode = SKSpriteNode(texture: gateTexture)
        
        let aspectRatio = gateTexture.size().width / gateTexture.size().height
        let sceneAspectRatio = self.size.width / self.size.height
        
        if aspectRatio > sceneAspectRatio {
            backgroundNode?.size.height = self.size.height
            backgroundNode?.size.width = self.size.height * aspectRatio
        } else {
            backgroundNode?.size.width = self.size.width
            backgroundNode?.size.height = self.size.width / aspectRatio
        }
        
        backgroundNode?.position = CGPoint.zero
        backgroundNode?.zPosition = Constants.ZPositions.background - 1
        if let bg = backgroundNode {
            addChild(bg)
        }
    }

    // Modified to accept 'visible' parameter
    func setupGameOverTitle(visible: Bool) {
        gameOverTitleNode = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        gameOverTitleNode?.text = "Game Over"
        gameOverTitleNode?.fontSize = 60
        gameOverTitleNode?.fontColor = .red
        gameOverTitleNode?.position = CGPoint(x: 0, y: self.size.height * 0.3)
        gameOverTitleNode?.zPosition = Constants.ZPositions.hud
        gameOverTitleNode?.isHidden = !visible
        if !visible { gameOverTitleNode?.alpha = 0 } 
        if let title = gameOverTitleNode {
            addChild(title)
        }
    }

    func setupScoreLabel(visible: Bool) {
        scoreLabelNode = SKLabelNode(fontNamed: "HelveticaNeue")
        scoreLabelNode?.text = "Final Score: \(finalScore)"
        scoreLabelNode?.fontSize = 40
        scoreLabelNode?.fontColor = .white
        scoreLabelNode?.position = CGPoint(x: 0, y: self.size.height * 0.05)
        scoreLabelNode?.zPosition = Constants.ZPositions.hud
        scoreLabelNode?.isHidden = !visible
        if !visible { scoreLabelNode?.alpha = 0 }
        if let label = scoreLabelNode {
            addChild(label)
        }
    }

    func setupBackButton(visible: Bool) {
        backButtonNode = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        backButtonNode?.text = "Back to Menu"
        backButtonNode?.fontSize = 30
        backButtonNode?.fontColor = .cyan
        backButtonNode?.position = CGPoint(x: 0, y: -self.size.height * 0.25)
        backButtonNode?.zPosition = Constants.ZPositions.hud
        backButtonNode?.name = "backButton"
        backButtonNode?.isHidden = !visible
        if !visible { backButtonNode?.alpha = 0 }
        if let button = backButtonNode {
            addChild(button)
        }
    }
    
    override func keyDown(with event: NSEvent) {
        guard contentReadyToShow else { return }

        if event.keyCode == 36 || event.keyCode == 76 {
            backToMenu()
        } else {
            super.keyDown(with: event)
        }
    }

    override func mouseDown(with event: NSEvent) {
        guard contentReadyToShow else { return }

        let location = event.location(in: self)
        let nodesAtPoint = nodes(at: location)

        for node in nodesAtPoint {
            if node.name == "backButton" {
                backToMenu()
                return
            }
        }
    }

    func backToMenu() {
        if let view = self.view {
            let menuScene = MenuScene(size: view.bounds.size)
            menuScene.scaleMode = self.scaleMode
            let transition = SKTransition.fade(withDuration: 1.0)
            view.presentScene(menuScene, transition: transition)
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if backgroundNode != nil {
            backgroundNode?.removeFromParent()
            setupBackground()
        }
        // Re-position UI elements based on new size
        gameOverTitleNode?.position = CGPoint(x: 0, y: self.size.height * 0.3)
        scoreLabelNode?.position = CGPoint(x: 0, y: self.size.height * 0.05)
        backButtonNode?.position = CGPoint(x: 0, y: -self.size.height * 0.25)
    }
}
