// Space Shooter/Game/Scenes/GameScene.swift
import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    private var player: PlayerNode!
    
    private var scoreLabel: SKLabelNode!
    private var healthLabel: SKLabelNode!
    
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

        setupScrollingBackground()
        setupPlayer()
        setupUI()
        startSpawning()
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
            backgroundNode.anchorPoint = .zero
            backgroundNode.size = CGSize(width: individualBackgroundWidth, height: scaledHeight)
            backgroundNode.position = CGPoint(x: CGFloat(i) * individualBackgroundWidth, y: 0)
            backgroundNode.zPosition = Constants.ZPositions.background
            backgroundNodes.append(backgroundNode)
            addChild(backgroundNode)
        }
    }

    func setupPlayer() {
        player = PlayerNode.newInstance(size: CGSize(width: 40, height: 40))
        player.position = CGPoint(x: player.size.width / 2 + 50, y: size.height / 2)
        addChild(player)
        player.updateThruster(isMoving: false)
    }

    func setupUI() {
        scoreLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.zPosition = Constants.ZPositions.hud
        addChild(scoreLabel)
        score = 0

        healthLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        healthLabel.fontSize = 24
        healthLabel.fontColor = .white
        healthLabel.horizontalAlignmentMode = .right
        healthLabel.zPosition = Constants.ZPositions.hud
        addChild(healthLabel)
        updateHealthLabel()
        
        updateUIPositions()
    }
    
    func updateUIPositions() {
        scoreLabel?.position = CGPoint(x: 20, y: size.height - 40)
        healthLabel?.position = CGPoint(x: size.width - 20, y: size.height - 40)
    }
    
    func updateHealthLabel() {
        guard player != nil, healthLabel != nil else { return }
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
        
        if event.keyCode == 49 {
            guard let player = self.player, player.parent != nil, let scene = self.scene else { return }
            player.shoot(currentTime: self.lastUpdateTime, scene: scene)
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
        // This is individualBackgroundWidth * backgroundNodes.count (which is now 3)
        let totalBackgroundWidth = individualBackgroundWidth * CGFloat(backgroundNodes.count)

        for backgroundNode in backgroundNodes {
            backgroundNode.position.x -= scrollAmount

            // If the background node's right edge is completely off-screen to the left
            if (backgroundNode.position.x + individualBackgroundWidth) < 0 {
                // Reposition it to the right end of the background chain
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
            player.position.x += dx
            player.position.y += dy
            
            let halfWidth = player.size.width / 2
            let halfHeight = player.size.height / 2
            
            player.position.x = max(halfWidth, player.position.x)
            player.position.x = min(size.width - halfWidth, player.position.x)
            player.position.y = max(halfHeight, player.position.y)
            player.position.y = min(size.height - halfHeight, player.position.y)
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
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

        if firstBody.categoryBitMask == Constants.PhysicsCategory.enemy && secondBody.categoryBitMask == Constants.PhysicsCategory.projectile {
            if let enemy = firstBody.node as? EnemyNode,
               let projectile = secondBody.node as? ProjectileNode, projectile.type == .player {
                projectileDidCollideWithEnemy(projectile: projectile, enemy: enemy)
            }
        }
        else if firstBody.categoryBitMask == Constants.PhysicsCategory.asteroid && secondBody.categoryBitMask == Constants.PhysicsCategory.projectile {
            if let asteroid = firstBody.node as? AsteroidNode,
               let projectile = secondBody.node as? ProjectileNode, projectile.type == .player {
                projectileDidCollideWithAsteroid(projectile: projectile, asteroid: asteroid)
            }
        }
        else if firstBody.categoryBitMask == Constants.PhysicsCategory.player && secondBody.categoryBitMask == Constants.PhysicsCategory.enemy {
            if let playerNode = firstBody.node as? PlayerNode, let enemyNode = secondBody.node as? EnemyNode {
                playerDidCollideWithObstacle(player: playerNode, obstacle: enemyNode)
            }
        }
        else if firstBody.categoryBitMask == Constants.PhysicsCategory.player && secondBody.categoryBitMask == Constants.PhysicsCategory.asteroid {
            if let playerNode = firstBody.node as? PlayerNode, let asteroidNode = secondBody.node as? AsteroidNode {
                 playerDidCollideWithObstacle(player: playerNode, obstacle: asteroidNode)
            }
        }
    }
    
    func projectileDidCollideWithEnemy(projectile: ProjectileNode, enemy: EnemyNode) {
        projectile.detonate()
        enemy.takeDamage(amount: 1, in: self)
        if enemy.health <= 0 {
            score += 10
        }
    }

    func projectileDidCollideWithAsteroid(projectile: ProjectileNode, asteroid: AsteroidNode) {
        projectile.detonate()
        asteroid.takeDamage(amount: 1, in: self)
    }

    func playerDidCollideWithObstacle(player: PlayerNode, obstacle: SKSpriteNode) {
        guard !isGameOverPending, player.health > 0 else { return }

        player.takeDamage(amount: 1, in: self)
       
        if let damageableObstacle = obstacle as? Damageable {
            damageableObstacle.takeDamage(amount: damageableObstacle.health, in: self)
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
        setupScrollingBackground()
        updateUIPositions()
    }
}
