import SpriteKit
import SwiftUI

class PlayerNode: SKSpriteNode, Damageable { // Conform to Damageable
    var health: Int = Constants.playerInitialHealth {
            didSet {
                // Notify GameScene to update health UI
                if let scene = self.scene as? GameScene {
                    scene.updateHealthUI()
                }
            }
        }
    private var lastShootTime: TimeInterval = 0
    private var thrusterEmitter: SKEmitterNode?

    static func newInstance(size: CGSize) -> PlayerNode {
        let texture = SKTexture(imageNamed: "Spaceship 1")
        let player = PlayerNode(texture: texture, color: .clear, size: CGSize(width: 150, height: 75))
        player.name = "player"

        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.size)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = Constants.PhysicsCategory.player
        player.physicsBody?.contactTestBitMask = Constants.PhysicsCategory.enemy | Constants.PhysicsCategory.asteroid // Add healthItem later
        player.physicsBody?.collisionBitMask = Constants.PhysicsCategory.none
        player.zPosition = Constants.ZPositions.player
        player.setupThruster()
        return player
    }
    
    func shoot(currentTime: TimeInterval, scene: SKScene) {
        guard currentTime - lastShootTime > Constants.playerShootCooldown else { return }
        lastShootTime = currentTime

        // Player projectile size
        let projectile = ProjectileNode.newInstance(type: .player, initialVisualSize: CGSize(width: 20, height: 8))
        
        let yOffset: CGFloat = -12
        let offsetX: CGFloat = self.size.width / 2 + projectile.calculateAccumulatedFrame().width / 2 + 5

        let projectileSpawnPoint = CGPoint(x: self.position.x + offsetX, y: self.position.y + yOffset)
        
        let velocity = CGVector(dx: Constants.projectileSpeed, dy: 0)
        projectile.launch(from: projectileSpawnPoint, initialVelocity: velocity, scene: scene)

    }
    // MARK: - Damageable
    func takeDamage(amount: Int, in scene: SKScene?) {
        health -= amount
        if health < 0 {
            health = 0
        }
        
        animateDamage(tintRed: true, shakeIntensity: 8.0) // Player shakes more
        print("Player health: \(health)")

        if health <= 0 {
            if let gameScene = scene as? GameScene {
                gameScene.gameOver()
            }
        }
    }

    func explode(in scene: SKScene?) {

        print("Player destroyed - Game Over sequence should be triggered by GameScene.")
        
        // self.removeFromParent()
    }

    private func setupThruster() {
            if let emitter = SKEmitterNode(fileNamed: "ThrusterEffect.sks") {
                emitter.position = CGPoint(x: -60, y: -self.size.height / 2 + 30)
                self.addChild(emitter)
                self.thrusterEmitter = emitter
            } else {
                print("Error: Could not load ThrusterEffect.sks")
            }
        }
    public func didMoveToScene() {
            if let thruster = self.thrusterEmitter, let scene = self.scene {
                thruster.targetNode = scene
            }
        }
    func updateThruster(isMoving: Bool) {
        didMoveToScene()
            if isMoving {
                thrusterEmitter?.particleBirthRate = 200
            } else {
                thrusterEmitter?.particleBirthRate = 20
            }
        }
}


#if DEBUG
@available(macOS 11.0, *)
struct PlayerNode_Previews: PreviewProvider {
    static var previews: some View {
        let scene = SKScene(size: CGSize(width: 200, height: 200))
        scene.backgroundColor = .darkGray
        scene.scaleMode = .aspectFit
        
        let player = PlayerNode.newInstance(size: CGSize(width: 40, height: 40))
        player.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2) 
        scene.addChild(player)
        
        
        return SpriteView(scene: scene)
            .frame(width: 200, height: 200)
            .ignoresSafeArea()
    }
}
#endif

