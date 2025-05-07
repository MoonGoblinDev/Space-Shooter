import SpriteKit
import SwiftUI

class PlayerNode: SKSpriteNode {
    var health: Int = Constants.playerInitialHealth
    private var lastShootTime: TimeInterval = 0
    private var thrusterEmitter: SKEmitterNode?

    static func newInstance(size: CGSize) -> PlayerNode {
        // Create a triangle path
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: size.height / 2))
        path.addLine(to: CGPoint(x: size.width / 2, y: 0)) // Tip pointing right
        path.addLine(to: CGPoint(x: 0, y: -size.height / 2))
        path.addLine(to: CGPoint(x: -size.width / 2, y: 0)) // Back edge
        path.closeSubpath()

        let shapeNode = SKShapeNode(path: path)
        shapeNode.fillColor = .green
        shapeNode.strokeColor = .green
        shapeNode.lineWidth = 2

        // Create a texture from the shape node
        let texture = SKTexture(imageNamed: "Spaceship 1")
        let player = PlayerNode(texture: texture, color: .clear, size: CGSize(width: 150, height: 75))
        player.name = "player"

        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.size)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = Constants.PhysicsCategory.player
        player.physicsBody?.contactTestBitMask = Constants.PhysicsCategory.enemy | Constants.PhysicsCategory.asteroid // Add healthItem later
        player.physicsBody?.collisionBitMask = Constants.PhysicsCategory.none // No actual pushing
        player.zPosition = Constants.ZPositions.player
        player.setupThruster()
        return player
    }
    
    func shoot(currentTime: TimeInterval, scene: SKScene) {
        guard currentTime - lastShootTime > Constants.playerShootCooldown else { return }
        lastShootTime = currentTime

        // The size here is for the physics body of the projectile.
        // The visual extent will be determined by the particle effect.
        let projectile = ProjectileNode.newInstance(type: .player, size: CGSize(width: 8, height: 8)) // Smaller hitbox
        
        let projectileSpawnOffset: CGFloat = 5
        projectile.position = CGPoint(x: self.position.x + self.size.width / 2, y: self.position.y - 20)
        scene.addChild(projectile)

        // The projectile node itself moves, and the emitter is its child.
        let moveAction = SKAction.moveBy(x: Constants.projectileSpeed * 2, y: 0, duration: 2.0)
        
        // When the projectile is removed, call detonate to handle particle fadeout
        let detonateAction = SKAction.run { projectile.detonate() }
        // If moveAction completes (goes off-screen), then detonate.
        projectile.run(SKAction.sequence([moveAction, detonateAction]))
    }

    func takeDamage(amount: Int = 1) {
        health -= amount
        if health < 0 {
            health = 0
        }
        // Add visual feedback for damage later (e.g., blinking)
        print("Player health: \(health)")
    }
    private func setupThruster() {
            if let emitter = SKEmitterNode(fileNamed: "ThrusterEffect.sks") {
                emitter.position = CGPoint(x: -60, y: -self.size.height / 2 + 30)

                
                self.addChild(emitter) // Add emitter as a child of the player initially
                self.thrusterEmitter = emitter

            } else {
                print("Error: Could not load ThrusterEffect.sks")
            }
        }
    public func didMoveToScene() {
            if let thruster = self.thrusterEmitter, let scene = self.scene {
                // Crucial step: Set the targetNode for world space simulation
                // This makes the particles emit into the scene's coordinate space,
                // appearing as if they are left behind.
                thruster.targetNode = scene
            }
        }
    func updateThruster(isMoving: Bool) {
        didMoveToScene()
            if isMoving {
                thrusterEmitter?.particleBirthRate = 200 // Or your desired rate for active thrust
                // Optional: Could also increase particle speed or change color
            } else {
                thrusterEmitter?.particleBirthRate = 20 // A small idle flicker, or 0 to turn off
            }
        }
}

#if DEBUG
@available(macOS 11.0, *)
struct PlayerNode_Previews: PreviewProvider {
    static var previews: some View {
        // Create a temporary scene to host the node
        let scene = SKScene(size: CGSize(width: 200, height: 200))
        scene.backgroundColor = .darkGray // So the node is visible
        scene.scaleMode = .aspectFit
        
        // Create an instance of your PlayerNode
        let player = PlayerNode.newInstance(size: CGSize(width: 40, height: 40))
        player.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2) // Center it
        scene.addChild(player)
        
        // You can add multiple variations or other nodes for context
        
        return SpriteView(scene: scene)
            .frame(width: 200, height: 200)
            .ignoresSafeArea()
    }
}
#endif

