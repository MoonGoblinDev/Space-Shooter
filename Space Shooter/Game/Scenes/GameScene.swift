import SpriteKit
import GameplayKit // For GKRandomSource, if needed later

class GameScene: SKScene, SKPhysicsContactDelegate {

    private var player: PlayerNode!
    
    private var scoreLabel: SKLabelNode!
    private var healthLabel: SKLabelNode!
    
    private var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    // Keyboard state
    private var keysPressed = Set<UInt16>()
    private var lastUpdateTime: TimeInterval = 0
    
    private var isGameOver = false


    override func didMove(to view: SKView) {
        backgroundColor = .black
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        // Anchor point to bottom-left for easier coordinate management
        anchorPoint = CGPoint(x: 0, y: 0)

        setupPlayer()
        setupUI()
        startSpawning()
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
        scoreLabel.position = CGPoint(x: 80, y: size.height - 40) // Adjusted for (0,0) anchor
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.zPosition = Constants.ZPositions.hud
        score = 0 // Triggers didSet
        addChild(scoreLabel)

        healthLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        healthLabel.fontSize = 24
        healthLabel.fontColor = .white
        healthLabel.position = CGPoint(x: size.width - 80, y: size.height - 40) // Adjusted for (0,0) anchor
        healthLabel.horizontalAlignmentMode = .right
        healthLabel.zPosition = Constants.ZPositions.hud
        updateHealthLabel()
        addChild(healthLabel)
    }
    
    func updateHealthLabel() {
        // Make sure player isn't nil, especially if health might be updated before player is fully set up
        guard player != nil else { return }
        healthLabel.text = "Health: \(player.health)"
    }

    func startSpawning() {
        // Check if actions already exist to prevent duplicates if scene is re-entered without proper cleanup
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
        guard !isGameOver else { return }
        let enemy = EnemyNode.newInstance(size: CGSize(width: 35, height: 35), sceneSize: self.size)
        addChild(enemy)
        enemy.startMoving()
    }

    func spawnAsteroid() {
        guard !isGameOver else { return }
        let asteroid = AsteroidNode.newInstance(sizeRange: (min: 50, max: 100), sceneSize: self.size)
        addChild(asteroid)
        asteroid.startMoving()
    }

    // MARK: - Keyboard Input
    override func keyDown(with event: NSEvent) {
        guard !isGameOver else { return } // Prevent input if game is over but scene hasn't transitioned
        keysPressed.insert(event.keyCode)
        
        if event.keyCode == 49 { // Spacebar
             // Use lastUpdateTime from the scene, not a new TimeInterval()
            player.shoot(currentTime: self.lastUpdateTime, scene: self)
        }
    }

    override func keyUp(with event: NSEvent) {
        keysPressed.remove(event.keyCode)
    }

    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        if isGameOver { return }
            
            if lastUpdateTime == 0 {
                lastUpdateTime = currentTime
            }
            let deltaTime = currentTime - lastUpdateTime
            lastUpdateTime = currentTime

            let playerIsMoving = !keysPressed.isEmpty // Simple check, refine if needed
            player?.updateThruster(isMoving: playerIsMoving && (keysPressed.contains(123) || keysPressed.contains(124) || keysPressed.contains(125) || keysPressed.contains(126)))

            processPlayerMovement(deltaTime: deltaTime)
    }
    
    func processPlayerMovement(deltaTime: TimeInterval) {
        guard player != nil else { return }

        var dx: CGFloat = 0
        var dy: CGFloat = 0
        var isActuallyMoving = false // Flag to see if any movement key results in displacement

        if keysPressed.contains(123) { // Left
            dx -= Constants.playerSpeed * CGFloat(deltaTime)
            isActuallyMoving = true
        }
        if keysPressed.contains(124) { // Right
            dx += Constants.playerSpeed * CGFloat(deltaTime)
            isActuallyMoving = true
        }
        if keysPressed.contains(126) { // Up
            dy += Constants.playerSpeed * CGFloat(deltaTime)
            isActuallyMoving = true
        }
        if keysPressed.contains(125) { // Down
            dy -= Constants.playerSpeed * CGFloat(deltaTime)
            isActuallyMoving = true
        }
        
        if isActuallyMoving { // Only update thruster if there's displacement due to keys
            player.position.x += dx
            player.position.y += dy
            
            // Boundary checks
            player.position.x = max(player.size.width/2, player.position.x)
            player.position.x = min(size.width - player.size.width/2, player.position.x)
            player.position.y = max(player.size.height/2, player.position.y)
            player.position.y = min(size.height - player.size.height/2, player.position.y)
        }
        
        // Update thruster based on whether movement keys are pressed, even if at boundary
        let movementKeysActive = keysPressed.contains(123) || keysPressed.contains(124) || keysPressed.contains(125) || keysPressed.contains(126)
        player.updateThruster(isMoving: movementKeysActive)
    }
    // MARK: - SKPhysicsContactDelegate
    func didBegin(_ contact: SKPhysicsContact) {
        if isGameOver { return }
        
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
        if (firstBody.categoryBitMask == Constants.PhysicsCategory.enemy && secondBody.categoryBitMask == Constants.PhysicsCategory.projectile) ||
           (firstBody.categoryBitMask == Constants.PhysicsCategory.projectile && secondBody.categoryBitMask == Constants.PhysicsCategory.enemy) {
            
            let enemyNode = (firstBody.categoryBitMask == Constants.PhysicsCategory.enemy ? firstBody.node : secondBody.node) as? EnemyNode
            let projectileNode = (firstBody.categoryBitMask == Constants.PhysicsCategory.projectile ? firstBody.node : secondBody.node) as? ProjectileNode

            if let enemy = enemyNode, let projectile = projectileNode, projectile.type == .player {
                projectileDidCollideWithEnemy(projectile: projectile, enemy: enemy)
            }
        }
        // Player Projectile vs Asteroid
        else if (firstBody.categoryBitMask == Constants.PhysicsCategory.asteroid && secondBody.categoryBitMask == Constants.PhysicsCategory.projectile) ||
                (firstBody.categoryBitMask == Constants.PhysicsCategory.projectile && secondBody.categoryBitMask == Constants.PhysicsCategory.asteroid) {

            let asteroidNode = (firstBody.categoryBitMask == Constants.PhysicsCategory.asteroid ? firstBody.node : secondBody.node) as? AsteroidNode
            let projectileNode = (firstBody.categoryBitMask == Constants.PhysicsCategory.projectile ? firstBody.node : secondBody.node) as? ProjectileNode
            
            if let asteroid = asteroidNode, let projectile = projectileNode, projectile.type == .player {
                projectileDidCollideWithAsteroid(projectile: projectile, asteroid: asteroid)
            }
        }
        // Player vs Enemy
        else if (firstBody.categoryBitMask == Constants.PhysicsCategory.player && secondBody.categoryBitMask == Constants.PhysicsCategory.enemy) ||
                (firstBody.categoryBitMask == Constants.PhysicsCategory.enemy && secondBody.categoryBitMask == Constants.PhysicsCategory.player) {
            
            let playerNode = (firstBody.categoryBitMask == Constants.PhysicsCategory.player ? firstBody.node : secondBody.node) as? PlayerNode
            let enemyNode = (firstBody.categoryBitMask == Constants.PhysicsCategory.enemy ? firstBody.node : secondBody.node) as? EnemyNode
            
            if let p = playerNode, let e_obstacle = enemyNode { // use a different variable name to avoid conflict if obstacle is also an EnemyNode
                playerDidCollideWithObstacle(player: p, obstacle: e_obstacle)
            }
        }
        // Player vs Asteroid
        else if (firstBody.categoryBitMask == Constants.PhysicsCategory.player && secondBody.categoryBitMask == Constants.PhysicsCategory.asteroid) ||
                (firstBody.categoryBitMask == Constants.PhysicsCategory.asteroid && secondBody.categoryBitMask == Constants.PhysicsCategory.player) {
            
            let playerNode = (firstBody.categoryBitMask == Constants.PhysicsCategory.player ? firstBody.node : secondBody.node) as? PlayerNode
            let asteroidNode = (firstBody.categoryBitMask == Constants.PhysicsCategory.asteroid ? firstBody.node : secondBody.node) as? AsteroidNode

            if let p = playerNode, let a_obstacle = asteroidNode { // use a different variable name
                 playerDidCollideWithObstacle(player: p, obstacle: a_obstacle)
            }
        }
    }
    
    func projectileDidCollideWithEnemy(projectile: ProjectileNode, enemy: EnemyNode) {
        projectile.detonate()
        enemy.removeFromParent()
        score += 10
    }

    func projectileDidCollideWithAsteroid(projectile: ProjectileNode, asteroid: AsteroidNode) {
        projectile.detonate()
        asteroid.removeFromParent()
        // score += 5 // Optional
    }

    func playerDidCollideWithObstacle(player: PlayerNode, obstacle: SKSpriteNode) {
        player.takeDamage()
        updateHealthLabel()
        obstacle.removeFromParent()
        
        if player.health <= 0 && !isGameOver { // Ensure gameOver runs only once
            gameOver()
        }
    }

    // In GameScene.swift - gameOver() method

    func gameOver() {
        print("Game Over - Transitioning to GameOverScene")
        isGameOver = true
        self.removeAllActions()
        keysPressed.removeAll()
        
        if let view = self.view {
                let gameOverScene = GameOverScene(size: view.bounds.size, score: self.score)
                gameOverScene.scaleMode = self.scaleMode

                // Let's say your transition is 0.8 seconds
                let transition = SKTransition.doorsCloseHorizontal(withDuration: 0.8)
                view.presentScene(gameOverScene, transition: transition)
            }
    }
}
