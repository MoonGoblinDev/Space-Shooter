import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    private var player: PlayerNode!
    
    private var scoreLabel: SKLabelNode!
    private var healthLabel: SKLabelNode!
    
    private var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    private var keysPressed = Set<UInt16>()
    private var lastUpdateTime: TimeInterval = 0 // Used for game logic and background
    
    private var isGameOverPending = false

    private var backgroundNodes: [SKSpriteNode] = [] // For scrolling background

    override func didMove(to view: SKView) {
        backgroundColor = .black // Fallback color
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        anchorPoint = CGPoint(x: 0, y: 0)

        setupScrollingBackground() // Call the new setup method
        setupPlayer()
        setupUI()
        startSpawning()
    }
    
    func setupScrollingBackground() {

        let backgroundTexture = SKTexture(imageNamed: "Nebula Blue")

        // Calculate scaled size to fit scene height while maintaining aspect ratio
        let aspectRatio = backgroundTexture.size().width / backgroundTexture.size().height
        let scaledHeight = size.height
        let scaledWidth = scaledHeight * aspectRatio
        
        for i in 0..<2 { // Create two nodes for seamless scrolling
            let backgroundNode = SKSpriteNode(texture: backgroundTexture)
            backgroundNode.anchorPoint = .zero // Important for anchor (0,0) scenes
            backgroundNode.size = CGSize(width: scaledWidth, height: scaledHeight)
            // Position for anchorPoint (0,0)
            // The first node starts at (0,0). The second is placed to its right.
            backgroundNode.position = CGPoint(x: CGFloat(i) * scaledWidth, y: 0)
            backgroundNode.zPosition = Constants.ZPositions.background
            backgroundNodes.append(backgroundNode)
            addChild(backgroundNode)
        }
    }

    func setupPlayer() {
        player = PlayerNode.newInstance(size: CGSize(width: 40, height: 40))
        player.position = CGPoint(x: 100, y: size.height / 2)
        addChild(player)
    }

    func setupUI() {
        scoreLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 80, y: size.height - 40)
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.zPosition = Constants.ZPositions.hud
        score = 0
        addChild(scoreLabel)

        healthLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        healthLabel.fontSize = 24
        healthLabel.fontColor = .white
        healthLabel.position = CGPoint(x: size.width - 80, y: size.height - 40)
        healthLabel.horizontalAlignmentMode = .right
        healthLabel.zPosition = Constants.ZPositions.hud
        updateHealthLabel()
        addChild(healthLabel)
    }
    
    func updateHealthLabel() {
        guard player != nil else { return }
        healthLabel.text = "Health: \(player.health)"
    }

    func startSpawning() {
        if action(forKey: "spawnEnemyAction") == nil {
            let spawnEnemyAction = SKAction.run(spawnEnemy)
            let waitEnemyAction = SKAction.wait(forDuration: Constants.enemySpawnInterval)
            let enemySequence = SKAction.sequence([spawnEnemyAction, waitEnemyAction])
            run(SKAction.repeatForever(enemySequence), withKey: "spawnEnemyAction")
        }

        if action(forKey: "spawnAsteroidAction") == nil {
            let spawnAsteroidAction = SKAction.run(spawnAsteroid)
            let waitAsteroidAction = SKAction.wait(forDuration: Constants.asteroidSpawnInterval)
            let asteroidSequence = SKAction.sequence([spawnAsteroidAction, waitAsteroidAction])
            run(SKAction.repeatForever(asteroidSequence), withKey: "spawnAsteroidAction")
        }
    }

    func spawnEnemy() {
        guard !isGameOverPending else { return }
        let enemy = EnemyNode.newInstance(size: CGSize(width: 35, height: 35), sceneSize: self.size)
        addChild(enemy)
        enemy.startMoving()
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
        
        if event.keyCode == 49 { // Spacebar
            player.shoot(currentTime: self.lastUpdateTime, scene: self)
        }
    }

    override func keyUp(with event: NSEvent) {
        keysPressed.remove(event.keyCode)
    }

    override func update(_ currentTime: TimeInterval) {
            // --- Game Logic DeltaTime ---
            var gameLogicDeltaTime: TimeInterval = 0
            if lastUpdateTime == 0 {
                lastUpdateTime = currentTime
            }
            gameLogicDeltaTime = currentTime - lastUpdateTime
            lastUpdateTime = currentTime
            // --- End Game Logic DeltaTime ---

            if isGameOverPending { return }
                
            scrollBackground(deltaTime: gameLogicDeltaTime) // Scroll background using game logic's deltaTime
            
            let playerIsActuallyMoving = keysPressed.contains(123) || keysPressed.contains(124) || keysPressed.contains(125) || keysPressed.contains(126)
            player?.updateThruster(isMoving: playerIsActuallyMoving)

            processPlayerMovement(deltaTime: gameLogicDeltaTime)
        }
        
        func scrollBackground(deltaTime: TimeInterval) {
            guard !backgroundNodes.isEmpty else { return }

            let scrollAmount = Constants.backgroundScrollSpeed * CGFloat(deltaTime)

            for backgroundNode in backgroundNodes {
                backgroundNode.position.x -= scrollAmount

                // Check if the node has scrolled completely off-screen to the left
                // For anchorPoint (0,0), this means its right edge is less than 0
                if (backgroundNode.position.x + backgroundNode.size.width) < 0 {
                    // Reposition it to the right of the *last* node in the current visual sequence.
                    // Essentially, move it over by the total width of all background segments.
                    backgroundNode.position.x += backgroundNode.size.width * CGFloat(backgroundNodes.count)
                }
            }
        }
    
    func processPlayerMovement(deltaTime: TimeInterval) {
        guard player != nil else { return }

        var dx: CGFloat = 0
        var dy: CGFloat = 0

        if keysPressed.contains(123) { dx -= Constants.playerSpeed * CGFloat(deltaTime) }
        if keysPressed.contains(124) { dx += Constants.playerSpeed * CGFloat(deltaTime) }
        if keysPressed.contains(126) { dy += Constants.playerSpeed * CGFloat(deltaTime) }
        if keysPressed.contains(125) { dy -= Constants.playerSpeed * CGFloat(deltaTime) }
        
        if dx != 0 || dy != 0 {
            player.position.x += dx
            player.position.y += dy
            
            player.position.x = max(player.size.width/2, player.position.x)
            player.position.x = min(size.width - player.size.width/2, player.position.x)
            player.position.y = max(player.size.height/2, player.position.y)
            player.position.y = min(size.height - player.size.height/2, player.position.y)
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        if isGameOverPending { return } // Don't process new contacts if game over is already triggered
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody

        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }

        // Player Projectile vs Enemy
        if firstBody.categoryBitMask == Constants.PhysicsCategory.enemy && secondBody.categoryBitMask == Constants.PhysicsCategory.projectile {
            if let enemy = firstBody.node as? EnemyNode,
               let projectile = secondBody.node as? ProjectileNode, projectile.type == .player {
                projectileDidCollideWithEnemy(projectile: projectile, enemy: enemy)
            }
        }
        // Player Projectile vs Asteroid
        else if firstBody.categoryBitMask == Constants.PhysicsCategory.asteroid && secondBody.categoryBitMask == Constants.PhysicsCategory.projectile {
            if let asteroid = firstBody.node as? AsteroidNode,
               let projectile = secondBody.node as? ProjectileNode, projectile.type == .player {
                projectileDidCollideWithAsteroid(projectile: projectile, asteroid: asteroid)
            }
        }
        // Player vs Enemy
        else if firstBody.categoryBitMask == Constants.PhysicsCategory.player && secondBody.categoryBitMask == Constants.PhysicsCategory.enemy {
            if let playerNode = firstBody.node as? PlayerNode, let enemyNode = secondBody.node as? EnemyNode {
                playerDidCollideWithObstacle(player: playerNode, obstacle: enemyNode)
            }
        }
        // Player vs Asteroid
        else if firstBody.categoryBitMask == Constants.PhysicsCategory.player && secondBody.categoryBitMask == Constants.PhysicsCategory.asteroid {
            if let playerNode = firstBody.node as? PlayerNode, let asteroidNode = secondBody.node as? AsteroidNode {
                 playerDidCollideWithObstacle(player: playerNode, obstacle: asteroidNode)
            }
        }
    }
    
    func projectileDidCollideWithEnemy(projectile: ProjectileNode, enemy: EnemyNode) {
        projectile.detonate()
        enemy.takeDamage(amount: 1, in: self) // Enemy takes 1 damage
        if enemy.health <= 0 { // Check if enemy was destroyed
            score += 10
        }
    }

    func projectileDidCollideWithAsteroid(projectile: ProjectileNode, asteroid: AsteroidNode) {
        projectile.detonate()
        asteroid.takeDamage(amount: 1, in: self) // Asteroid takes 1 damage
        if asteroid.health <= 0 {
             // score += 5 // Optional score for destroying asteroid
        }
    }

    func playerDidCollideWithObstacle(player: PlayerNode, obstacle: SKSpriteNode) {
        guard !isGameOverPending else { return } // Double check

        // Player takes damage
        // Only inflict damage if player is still alive
        if player.health > 0 {
             player.takeDamage(amount: 1, in: self) // Player takes 1 damage
        }
       
        // Obstacle is also destroyed by colliding with player
        if let damageableObstacle = obstacle as? Damageable {
            // Hit it hard enough to destroy it in one go from player collision
            damageableObstacle.takeDamage(amount: damageableObstacle.health, in: self)
        } else {
            // Fallback for obstacles not conforming to Damageable
            obstacle.removeFromParent()
        }
        
        // Check for game over condition (moved to PlayerNode's takeDamage, but can be double-checked here)
        if player.health <= 0 && !isGameOverPending {
            gameOver()
        }
    }

    func gameOver() {
        guard !isGameOverPending else { return } // Ensure this is called only once
        isGameOverPending = true // Set the flag
        
        print("Game Over - Transitioning to GameOverScene")
        
        // Stop all actions in this scene (like spawning)
        self.removeAllActions()
        // Stop player movement input
        keysPressed.removeAll()
        
        // Make player visually "explode" or disappear before transitioning scene
        if player.parent != nil { // Check if player is still in scene
             ExplosionNode.showExplosion(at: player.position, in: self)
             player.removeFromParent()
        }

        // Delay transition slightly to allow explosion to be seen
        let waitAction = SKAction.wait(forDuration: 0.5) // Adjust as needed
        let transitionAction = SKAction.run { [weak self] in
            guard let self = self, let view = self.view else { return }
            let gameOverScene = GameOverScene(size: view.bounds.size, score: self.score)
            gameOverScene.scaleMode = self.scaleMode
            let transition = SKTransition.doorsCloseHorizontal(withDuration: 0.8)
            view.presentScene(gameOverScene, transition: transition)
        }
        
        run(SKAction.sequence([waitAction, transitionAction]))
    }
}
