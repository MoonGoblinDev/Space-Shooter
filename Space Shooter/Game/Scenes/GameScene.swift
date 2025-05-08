// Space Shooter/Game/Scenes/GameScene.swift
import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    private var player: PlayerNode!
    
    private var scoreLabel: SKLabelNode!
    // private var healthLabel: SKLabelNode! // Removed
    private var healthNodes: [SKSpriteNode] = [] // To store heart sprites
    private var fullHeartTexture: SKTexture?
    private var emptyHeartTexture: SKTexture? // Optional: for a different "empty" heart look

    private var score: Int = 0 {
        didSet {
            scoreLabel?.text = "Score: \(score)"
        }
    }
    
    private var keysPressed = Set<UInt16>()
    private var lastUpdateTime: TimeInterval = 0
    
    private var isGameOverPending = false

    private var backgroundNodes: [SKSpriteNode] = []
    private var individualBackgroundWidth: CGFloat = 0

    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        anchorPoint = CGPoint(x: 0, y: 0)

        preloadHeartTextures() // Preload textures for hearts
        setupScrollingBackground()
        setupPlayer()
        setupUI()
        startSpawning()
    }

    func preloadHeartTextures() {
        if #available(macOS 11.0, *) {
            if let fullHeartImage = NSImage(systemSymbolName: "heart.fill", accessibilityDescription: "Full Health") {
                fullHeartImage.isTemplate = true // Allows tinting with node.color
                // Forcing a tint to red directly for the texture
                let redTintedFullHeartImage = fullHeartImage.tinted(with: .red)
                self.fullHeartTexture = SKTexture(image: redTintedFullHeartImage)
            } else {
                print("Error: SF Symbol 'heart.fill' not found.")
                // Fallback texture if needed
            }

            if let emptyHeartImage = NSImage(systemSymbolName: "heart", accessibilityDescription: "Empty Health") { // Using "heart" for empty
                emptyHeartImage.isTemplate = true
                let grayTintedEmptyHeartImage = emptyHeartImage.tinted(with: .darkGray)
                self.emptyHeartTexture = SKTexture(image: grayTintedEmptyHeartImage) // Tinted gray
            } else {
                print("Error: SF Symbol 'heart' not found.")
                // Fallback texture if needed
            }
        } else {
            // Fallback for older macOS versions if you don't have SF Symbols
            // Or use placeholder colored squares
            print("Warning: SF Symbols require macOS 11+. Health icons might not appear correctly.")
            let fallbackFull = SKSpriteNode(color: .red, size: Constants.hudHeartSize)
            let fallbackEmpty = SKSpriteNode(color: .gray, size: Constants.hudHeartSize)
            self.fullHeartTexture = view?.texture(from: fallbackFull)
            self.emptyHeartTexture = view?.texture(from: fallbackEmpty)
        }
    }
    
    func setupScrollingBackground() {
        // ... (no changes here)
        for node in backgroundNodes {
            node.removeFromParent()
        }
        backgroundNodes.removeAll()

        let backgroundTexture = SKTexture(imageNamed: "Nebula Blue")
        backgroundTexture.filteringMode = .nearest

        let aspectRatio = backgroundTexture.size().width / backgroundTexture.size().height
        let scaledHeight = size.height
        self.individualBackgroundWidth = scaledHeight * aspectRatio
        
        let numberOfSegments = 3

        for i in 0..<numberOfSegments {
            let backgroundNode = SKSpriteNode(texture: backgroundTexture)
            backgroundNode.anchorPoint = .zero
            backgroundNode.size = CGSize(width: individualBackgroundWidth, height: scaledHeight)
            backgroundNode.position = CGPoint(x: CGFloat(i) * individualBackgroundWidth, y: 0)
            backgroundNode.zPosition = Constants.ZPositions.background
            backgroundNodes.append(backgroundNode)
            addChild(backgroundNode)
        }
    }

    func setupPlayer() {
        // ... (no changes here)
        player = PlayerNode.newInstance(size: CGSize(width: 150, height: 75))
        player.position = CGPoint(x: player.size.width, y: size.height / 2)
        addChild(player)
        player.updateThruster(isMoving: false)
    }

    func setupUI() {
        // Score Label
        scoreLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.zPosition = Constants.ZPositions.hud
        addChild(scoreLabel)
        score = 0 // Triggers didSet to update text

        // Health Hearts
        healthNodes.forEach { $0.removeFromParent() } // Clear old hearts if any (e.g., on resize)
        healthNodes.removeAll()

        for _ in 0..<Constants.playerInitialHealth {
            let heartNode = SKSpriteNode(texture: fullHeartTexture ?? SKTexture()) // Use preloaded texture
            heartNode.size = Constants.hudHeartSize
            heartNode.zPosition = Constants.ZPositions.hudForeground // Ensure hearts are visible
            // Initial color/texture is handled by updateHealthUI
            healthNodes.append(heartNode)
            addChild(heartNode)
        }
        
        updateUIPositions() // Position score and hearts
        updateHealthUI()    // Set initial heart states
    }
    
    func updateUIPositions() {
        scoreLabel?.position = CGPoint(x: Constants.hudSideMargin, y: size.height - Constants.hudTopMargin)
        
        for (index, heartNode) in healthNodes.enumerated() {
            let xPos = size.width - Constants.hudSideMargin - (CGFloat(index) * (Constants.hudHeartSize.width + Constants.hudHeartSpacing)) - Constants.hudHeartSize.width / 2
            let yPos = size.height - Constants.hudTopMargin
            heartNode.position = CGPoint(x: xPos, y: yPos)
        }
    }
    
    // Renamed from updateHealthLabel
    func updateHealthUI() {
        guard player != nil else { return }

        for (index, heartNode) in healthNodes.enumerated() {
            if index < player.health {
                heartNode.texture = fullHeartTexture
                // heartNode.color = .red // Not needed if texture is already red
                // heartNode.alpha = 1.0
            } else {
                if let emptyTex = emptyHeartTexture {
                    heartNode.texture = emptyTex
                } else { // Fallback if emptyHeartTexture is nil
                    heartNode.texture = fullHeartTexture // Show full heart but make it look "empty"
                    heartNode.alpha = 0.3 // Example: make "empty" hearts faded
                }
            }
            // Ensure colorBlendFactor is 0 if textures are pre-tinted, or 1 if you are tinting a template texture here.
            // Since we are pre-tinting the NSImage to create the SKTexture, colorBlendFactor is not primarily used here.
            heartNode.colorBlendFactor = 0.0
        }
    }

    // ... (startSpawning, spawnEnemy, spawnAsteroid, keyDown, keyUp, update, scrollBackground, processPlayerMovement remain the same) ...
    func startSpawning() {
        if action(forKey: "spawnEnemyAction") == nil {
            let spawnEnemyAction = SKAction.run(spawnEnemy)
            let waitEnemyAction = SKAction.wait(forDuration: Constants.enemySpawnInterval, withRange: Constants.enemySpawnInterval * 0.5)
            let enemySequence = SKAction.sequence([spawnEnemyAction, waitEnemyAction])
            run(SKAction.repeatForever(enemySequence), withKey: "spawnEnemyAction")
        }

        if action(forKey: "spawnAsteroidAction") == nil {
            let spawnAsteroidAction = SKAction.run(spawnAsteroid)
            let waitAsteroidAction = SKAction.wait(forDuration: Constants.asteroidSpawnInterval, withRange: Constants.asteroidSpawnInterval * 0.5)
            let asteroidSequence = SKAction.sequence([spawnAsteroidAction, waitAsteroidAction])
            run(SKAction.repeatForever(asteroidSequence), withKey: "spawnAsteroidAction")
        }
    }

    func spawnEnemy() {
        guard !isGameOverPending else { return }
        let enemy = EnemyNode.newInstance(size: CGSize(width: 75, height: 50), sceneSize: self.size)
        addChild(enemy)
        enemy.startMoving()
        enemy.startShooting(in: self)
    }

    func spawnAsteroid() {
        guard !isGameOverPending else { return }
        let asteroid = AsteroidNode.newInstance(sizeRange: (min: 50, max: 100), sceneSize: self.size)
        addChild(asteroid)
        asteroid.startMoving()
    }

    override func keyDown(with event: NSEvent) {
        guard !isGameOverPending else { return }
        keysPressed.insert(event.keyCode)
        
        if event.keyCode == 49 {
            guard let player = self.player, player.parent != nil else { return }
            player.shoot(currentTime: self.lastUpdateTime, scene: self)
        }
    }

    override func keyUp(with event: NSEvent) {
        keysPressed.remove(event.keyCode)
    }

    override func update(_ currentTime: TimeInterval) {
        var gameLogicDeltaTime: TimeInterval = 0
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        gameLogicDeltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        if isGameOverPending { return }
            
        let maxDeltaTime: TimeInterval = 1.0 / 30.0
        let cappedDeltaTime = min(gameLogicDeltaTime, maxDeltaTime)

        scrollBackground(deltaTime: cappedDeltaTime)
        
        let playerIsActuallyMoving = keysPressed.contains(123) || keysPressed.contains(124) || keysPressed.contains(125) || keysPressed.contains(126)
        player?.updateThruster(isMoving: playerIsActuallyMoving)

        processPlayerMovement(deltaTime: cappedDeltaTime)
    }
    
    func scrollBackground(deltaTime: TimeInterval) {
        guard !backgroundNodes.isEmpty, individualBackgroundWidth > 0 else { return }

        let scrollAmount = Constants.backgroundScrollSpeed * CGFloat(deltaTime)
        let totalBackgroundWidth = individualBackgroundWidth * CGFloat(backgroundNodes.count)

        for backgroundNode in backgroundNodes {
            backgroundNode.position.x -= scrollAmount
            if (backgroundNode.position.x + individualBackgroundWidth) < 0 {
                backgroundNode.position.x += totalBackgroundWidth
            }
        }
    }
    
    func processPlayerMovement(deltaTime: TimeInterval) {
        guard let player = self.player, player.parent != nil else { return }

        var dx: CGFloat = 0
        var dy: CGFloat = 0

        let effectiveSpeed = Constants.playerSpeed * CGFloat(deltaTime)

        if keysPressed.contains(123) { dx -= effectiveSpeed }
        if keysPressed.contains(124) { dx += effectiveSpeed }
        if keysPressed.contains(126) { dy += effectiveSpeed }
        if keysPressed.contains(125) { dy -= effectiveSpeed }
        
        if dx != 0 || dy != 0 {
            let newX = player.position.x + dx
            let newY = player.position.y + dy
            
            let halfWidth = player.size.width / 2
            let halfHeight = player.size.height / 2
            
            player.position.x = max(halfWidth, min(newX, size.width - halfWidth))
            player.position.y = max(halfHeight, min(newY, size.height - halfHeight))
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        // ... (contact logic remains the same, ensure player.takeDamage calls will trigger updateHealthUI) ...
        if isGameOverPending { return }
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody

        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }

        if firstBody.categoryBitMask == Constants.PhysicsCategory.enemy &&
           secondBody.categoryBitMask == Constants.PhysicsCategory.projectile {
            if let enemy = firstBody.node as? EnemyNode,
               let projectile = secondBody.node as? ProjectileNode, projectile.type == .player {
                projectileDidCollideWithEnemy(projectile: projectile, enemy: enemy)
            }
        }
        else if firstBody.categoryBitMask == Constants.PhysicsCategory.asteroid &&
                secondBody.categoryBitMask == Constants.PhysicsCategory.projectile {
            if let asteroid = firstBody.node as? AsteroidNode,
               let projectile = secondBody.node as? ProjectileNode, projectile.type == .player {
                projectileDidCollideWithAsteroid(projectile: projectile, asteroid: asteroid)
            }
        }
        else if firstBody.categoryBitMask == Constants.PhysicsCategory.player &&
                secondBody.categoryBitMask == Constants.PhysicsCategory.enemy {
            if let playerNode = firstBody.node as? PlayerNode, let enemyNode = secondBody.node as? EnemyNode {
                playerDidCollideWithObstacle(player: playerNode, obstacle: enemyNode)
            }
        }
        else if firstBody.categoryBitMask == Constants.PhysicsCategory.player &&
                secondBody.categoryBitMask == Constants.PhysicsCategory.asteroid {
            if let playerNode = firstBody.node as? PlayerNode, let asteroidNode = secondBody.node as? AsteroidNode {
                 playerDidCollideWithObstacle(player: playerNode, obstacle: asteroidNode)
            }
        }
        else if firstBody.categoryBitMask == Constants.PhysicsCategory.player &&
                secondBody.categoryBitMask == Constants.PhysicsCategory.projectile {
            if let playerNode = firstBody.node as? PlayerNode,
               let projectileNode = secondBody.node as? ProjectileNode, projectileNode.type == .enemy {
                playerDidCollideWithEnemyProjectile(player: playerNode, projectile: projectileNode)
            }
        }
    }
    
    func projectileDidCollideWithEnemy(projectile: ProjectileNode, enemy: EnemyNode) {
        projectile.removeAction(forKey: "projectileLifetime")
        projectile.detonate()
        enemy.takeDamage(amount: 1, in: self)
        if enemy.health <= 0 {
            score += 10
        }
    }

    func projectileDidCollideWithAsteroid(projectile: ProjectileNode, asteroid: AsteroidNode) {
        projectile.removeAction(forKey: "projectileLifetime")
        projectile.detonate()
        asteroid.takeDamage(amount: 1, in: self)
    }
    
    func playerDidCollideWithEnemyProjectile(player: PlayerNode, projectile: ProjectileNode) {
        projectile.removeAction(forKey: "projectileLifetime")
        projectile.detonate()
        player.takeDamage(amount: 1, in: self)
    }

    func playerDidCollideWithObstacle(player: PlayerNode, obstacle: SKSpriteNode) {
        guard !isGameOverPending, player.health > 0 else { return }
        player.takeDamage(amount: 1, in: self)
        if let damageableObstacle = obstacle as? Damageable {
            damageableObstacle.takeDamage(amount: damageableObstacle.health > 0 ? damageableObstacle.health : 1000, in: self)
        } else {
            ExplosionNode.showExplosion(at: obstacle.position, in: self)
            obstacle.removeFromParent()
        }
    }

    func gameOver() {
        guard !isGameOverPending else { return }
        isGameOverPending = true
        
        self.removeAllActions()
        keysPressed.removeAll()
        
        enumerateChildNodes(withName: "enemy") { (node, _) in
            node.removeAllActions()
            if let enemyNode = node as? EnemyNode {
                enemyNode.stopShooting()
            }
        }
        enumerateChildNodes(withName: "asteroid") { (node, _) in node.removeAllActions() }
        enumerateChildNodes(withName: "projectile_*") { (node, _) in node.removeAllActions(); node.removeFromParent() }
        healthNodes.forEach { $0.isHidden = true } // Hide hearts on game over

        if let playerNode = self.player, playerNode.parent != nil {
             ExplosionNode.showExplosion(at: playerNode.position, in: self)
             playerNode.removeFromParent()
             self.player = nil
        }

        let waitAction = SKAction.wait(forDuration: 0.8)
        let transitionAction = SKAction.run { [weak self] in
            guard let self = self, let view = self.view else { return }
            let gameOverScene = GameOverScene(size: view.bounds.size, score: self.score)
            gameOverScene.scaleMode = self.scaleMode
            let transition = SKTransition.doorsCloseHorizontal(withDuration: 0.8)
            view.presentScene(gameOverScene, transition: transition)
        }
        run(SKAction.sequence([waitAction, transitionAction]))
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // Existing elements
        setupScrollingBackground()
        updateUIPositions() // This will re-position score and hearts

        // Player boundary check update
        if let player = player {
             let halfWidth = player.size.width / 2
             let halfHeight = player.size.height / 2
             player.position.x = max(halfWidth, min(player.position.x, size.width - halfWidth))
             player.position.y = max(halfHeight, min(player.position.y, size.height - halfHeight))
        }
    }
}

// Helper extension for NSImage tinting (macOS specific)
@available(macOS 10.10, *) // NSImage.tinted needs a good baseline
extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        // Forcing isTemplate = true is crucial for system symbols if they are not already templates.
        // If the image comes from a file and has color, this approach might fully overlay it.
        // For SF Symbols, this works well.
        let newImage = self.copy() as! NSImage
        newImage.lockFocus()
        color.set()
        let imageRect = NSRect(origin: .zero, size: newImage.size)
        imageRect.fill(using: .sourceAtop)
        newImage.unlockFocus()
        return newImage
    }
}
