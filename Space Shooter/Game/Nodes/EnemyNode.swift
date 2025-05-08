// Space Shooter/Game/Nodes/EnemyNode.swift
import SpriteKit
import SwiftUI // Keep if you use previews

class EnemyNode: SKSpriteNode, Damageable {
    var health: Int = Constants.enemyInitialHealth
    private var initialYPosition: CGFloat = 0.0
    private let shootActionKey = "enemyShootingAction"

    static func newInstance(size: CGSize, sceneSize: CGSize) -> EnemyNode {
        let texture = SKTexture(imageNamed: "Minion 1")
        let enemy = EnemyNode(texture: texture, color: .clear, size: CGSize(width: 75, height: 50))
        enemy.name = "enemy"

        let randomY = CGFloat.random(in: enemy.size.height/2 + Constants.enemySineAmplitude...(sceneSize.height - enemy.size.height/2 - Constants.enemySineAmplitude))
        enemy.position = CGPoint(x: sceneSize.width + enemy.size.width / 2, y: randomY)
        enemy.initialYPosition = randomY

        enemy.physicsBody = SKPhysicsBody(texture: enemy.texture!, size: enemy.size)
        enemy.physicsBody?.isDynamic = true
        enemy.physicsBody?.affectedByGravity = false
        enemy.physicsBody?.categoryBitMask = Constants.PhysicsCategory.enemy
        enemy.physicsBody?.contactTestBitMask = Constants.PhysicsCategory.projectile | Constants.PhysicsCategory.player
        enemy.physicsBody?.collisionBitMask = Constants.PhysicsCategory.none
        enemy.zPosition = Constants.ZPositions.enemy
        
        return enemy
    }

    func startMoving() {
        guard let scene = self.scene else { return }

        let horizontalSpeed = Constants.enemySpeed
        let amplitude = Constants.enemySineAmplitude
        let angularFrequency = Constants.enemySineFrequency * 2 * .pi
        let totalHorizontalDistance = scene.size.width + self.size.width
        let duration = totalHorizontalDistance / horizontalSpeed
        let startX = self.position.x
        
        let moveAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
            let newX = startX - (horizontalSpeed * elapsedTime)
            let newY = self.initialYPosition + (amplitude * sin(angularFrequency * elapsedTime))
            node.position = CGPoint(x: newX, y: newY)
        }
        
        let removeAction = SKAction.removeFromParent()
        self.run(SKAction.sequence([moveAction, removeAction]), withKey: "movement")
    }

    func startShooting(in scene: SKScene) {
        stopShooting() // Clear previous shooting action if any

        let shootClosure = { [weak self, weak scene] in
            guard let self = self, let scene = scene, self.parent != nil else { return }
            self.shoot(in: scene)
        }

        let initialDelay = SKAction.wait(forDuration: TimeInterval.random(in: 0.5...Constants.enemyMinShootInterval)) // Initial delay before first shot
        let shootOnceAction = SKAction.run(shootClosure)
        let waitBetweenShots = SKAction.wait(forDuration: TimeInterval.random(in: Constants.enemyMinShootInterval...Constants.enemyMaxShootInterval),
                                           withRange: (Constants.enemyMaxShootInterval - Constants.enemyMinShootInterval) * 0.4) // Add some randomness
        
        let shootSequence = SKAction.sequence([shootOnceAction, waitBetweenShots])
        let repeatShootingAction = SKAction.repeatForever(shootSequence)
        
        self.run(SKAction.sequence([initialDelay, repeatShootingAction]), withKey: shootActionKey)
    }

    func stopShooting() {
        self.removeAction(forKey: shootActionKey)
    }

    private func shoot(in scene: SKScene) {
        guard self.parent != nil else { return } // Don't shoot if not in scene

        // Create an enemy projectile
        // Assuming EnemyProjectile.sks points left, or adjust emitter rotation in ProjectileNode
        let projectile = ProjectileNode.newInstance(type: .enemy, initialVisualSize: CGSize(width: 15, height: 5)) // Adjust size as needed

        // Position the projectile to fire from the front-left of the enemy
        let offsetX:CGFloat = -self.size.width / 2 - projectile.calculateAccumulatedFrame().width / 2 - 5
        let projectileSpawnPoint = CGPoint(x: self.position.x + offsetX, y: self.position.y)
        
        let velocity = CGVector(dx: Constants.enemyProjectileSpeed, dy: 0)
        projectile.launch(from: projectileSpawnPoint, initialVelocity: velocity, scene: scene)

        // Play shoot sound if you have one
        // SoundManager.shared.playSound(.enemyShoot)
    }

    // MARK: - Damageable
    func takeDamage(amount: Int, in scene: SKScene?) {
        health -= amount
        
        if health > 0 {
            animateDamage(tintRed: true, shakeIntensity: 4.0)
        } else {
            self.removeAction(forKey: "movement")
            self.stopShooting() // Stop shooting when destroyed
            explode(in: scene) // This will call ExplosionNode.showExplosion and self.removeFromParent()
        }
    }
    // explode() and animateDamage() are provided by the Damageable extension
}

// ... (Keep the Previews if you use them) ...
#if DEBUG
@available(macOS 11.0, *)
struct EnemyNode_Previews: PreviewProvider {
    static var previews: some View {
        let scene = SKScene(size: CGSize(width: 200, height: 200))
        scene.backgroundColor = .darkGray
        scene.scaleMode = .aspectFit
        
        let enemy = EnemyNode.newInstance(size: CGSize(width: 40, height: 40), sceneSize: CGSize(width: 200, height: 200))
        enemy.position = CGPoint(x: scene.size.width * 0.75, y: scene.size.height / 2)
        scene.addChild(enemy)
        enemy.startShooting(in: scene) // For previewing shooting
        
        return SpriteView(scene: scene)
            .frame(width: 200, height: 200)
            .ignoresSafeArea()
    }
}
#endif
