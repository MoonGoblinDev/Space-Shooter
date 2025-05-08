import SpriteKit
import SwiftUI

class EnemyNode: SKSpriteNode, Damageable {
    var health: Int = Constants.enemyInitialHealth
    private var initialYPosition: CGFloat = 0.0 // To store the baseline Y for sinusoidal movement

    static func newInstance(size: CGSize, sceneSize: CGSize) -> EnemyNode {
        // ... (shape node and texture creation remains the same) ...
        let texture = SKTexture(imageNamed: "Minion 1")
        let enemy = EnemyNode(texture: texture, color: .clear, size: CGSize(width: 75, height: 50))
        enemy.name = "enemy"

        // Spawn on the right, random Y
        let randomY = CGFloat.random(in: enemy.size.height/2 + Constants.enemySineAmplitude...(sceneSize.height - enemy.size.height/2 - Constants.enemySineAmplitude))
        // Ensure spawn Y considers amplitude to prevent going off-screen immediately
        enemy.position = CGPoint(x: sceneSize.width + enemy.size.width / 2, y: randomY)
        enemy.initialYPosition = randomY // Store the initial Y position

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
        // Frequency in cycles per second, convert to angular frequency for sin function
        let angularFrequency = Constants.enemySineFrequency * 2 * .pi

        // Calculate total distance and duration for horizontal movement
        let totalHorizontalDistance = scene.size.width + self.size.width
        let duration = totalHorizontalDistance / horizontalSpeed

        // Store initial X position for the custom action
        let startX = self.position.x
        
        // Custom action for combined horizontal and sinusoidal vertical movement
        let moveAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
            // Calculate new X based on constant speed
            let newX = startX - (horizontalSpeed * elapsedTime)
            
            // Calculate new Y using sine wave
            // elapsedTime progresses from 0 to 'duration'
            let newY = self.initialYPosition + (amplitude * sin(angularFrequency * elapsedTime))
            
            node.position = CGPoint(x: newX, y: newY)
        }
        
        let removeAction = SKAction.removeFromParent()
        self.run(SKAction.sequence([moveAction, removeAction]), withKey: "movement")
    }

    // MARK: - Damageable
    func takeDamage(amount: Int, in scene: SKScene?) {
        health -= amount
        
        if health > 0 {
            animateDamage(tintRed: true, shakeIntensity: 4.0)
        } else {
            self.removeAction(forKey: "movement") // Stop movement if destroyed
            explode(in: scene)
        }
    }
    // explode() and animateDamage() are provided by the Damageable extension
}

// ... (Keep the Previews if you use them) ...

#if DEBUG
@available(macOS 11.0, *)
struct EnemyNode_Previews: PreviewProvider {
    static var previews: some View {
        // Create a temporary scene to host the node
        let scene = SKScene(size: CGSize(width: 200, height: 200))
        scene.backgroundColor = .darkGray // So the node is visible
        scene.scaleMode = .aspectFit
        
        // Create an instance of your PlayerNode
        let enemy = EnemyNode.newInstance(size: CGSize(width: 40, height: 40), sceneSize: CGSize(width: 200, height: 200))
        enemy.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2) // Center it
        scene.addChild(enemy)
        
        // You can add multiple variations or other nodes for context
        
        return SpriteView(scene: scene)
            .frame(width: 200, height: 200)
            .ignoresSafeArea()
    }
}
#endif
