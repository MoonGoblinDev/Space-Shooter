import SpriteKit

class GameOverScene: SKScene {

    var finalScore: Int = 0

    // Custom initializer to accept the score
    init(size: CGSize, score: Int) {
        self.finalScore = score
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = CGPoint(x: 0.5, y: 0.5) // Center anchor

        setupGameOverTitle()
        setupScoreLabel()
        setupBackButton()
    }

    func setupGameOverTitle() {
        let gameOverLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        gameOverLabel.text = "Game Over"
        gameOverLabel.fontSize = 60
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: 0, y: 150) // Relative to center
        gameOverLabel.zPosition = Constants.ZPositions.hud
        addChild(gameOverLabel)
    }

    func setupScoreLabel() {
        let scoreDisplayLabel = SKLabelNode(fontNamed: "HelveticaNeue")
        scoreDisplayLabel.text = "Final Score: \(finalScore)"
        scoreDisplayLabel.fontSize = 40
        scoreDisplayLabel.fontColor = .white
        scoreDisplayLabel.position = CGPoint(x: 0, y: 50) // Below "Game Over"
        scoreDisplayLabel.zPosition = Constants.ZPositions.hud
        addChild(scoreDisplayLabel)
    }

    func setupBackButton() {
        let backButtonLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        backButtonLabel.text = "Back to Menu"
        backButtonLabel.fontSize = 30
        backButtonLabel.fontColor = .cyan
        backButtonLabel.position = CGPoint(x: 0, y: -100) // Below score
        backButtonLabel.zPosition = Constants.ZPositions.hud
        backButtonLabel.name = "backButton" // For identifying the node on touch/click
        addChild(backButtonLabel)

        // Optional: Add a subtle pulse or highlight effect for interactivity feedback
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.3)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.3)
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        // backButtonLabel.run(SKAction.repeatForever(pulse)) // Or trigger on hover for macOS
    }
    
    // For macOS, we'll use keyDown for simplicity, but mouseDown is also an option for "buttons"
    override func keyDown(with event: NSEvent) {
        // KeyCode 36 is Return (Enter)
        // KeyCode 76 is Enter on the numeric keypad
        if event.keyCode == 36 || event.keyCode == 76 {
            backToMenu()
        } else {
            super.keyDown(with: event)
        }
    }

    // If you want to use mouse clicks for the "button"
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let nodesAtPoint = nodes(at: location)

        for node in nodesAtPoint {
            if node.name == "backButton" {
                backToMenu()
                return // Important: exit after handling the click
            }
        }
    }

    func backToMenu() {
        if let view = self.view {
            let menuScene = MenuScene(size: view.bounds.size)
            menuScene.scaleMode = self.scaleMode // Use the same scale mode

            let transition = SKTransition.fade(withDuration: 1.0)
            view.presentScene(menuScene, transition: transition)
        }
    }
}
