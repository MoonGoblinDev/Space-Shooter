import SpriteKit
import SwiftUI

class EnemyNode: SKSpriteNode {
    // For now, enemies are destroyed in one hit
    static func newInstance(size: CGSize, sceneSize: CGSize) -> EnemyNode {
        // Create a triangle path (pointing left)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: size.height / 2))
        path.addLine(to: CGPoint(x: size.width / 2, y: 0)) // Tip pointing right
        path.addLine(to: CGPoint(x: 0, y: -size.height / 2))
        path.addLine(to: CGPoint(x: -size.width / 2, y: 0)) // Back edge
        path.closeSubpath()

        let shapeNode = SKShapeNode(path: path)
        shapeNode.fillColor = .purple
        shapeNode.strokeColor = .purple
        shapeNode.lineWidth = 2

        let texture = SKTexture(imageNamed: "Minion 1")
        let enemy = EnemyNode(texture: texture, color: .clear, size: CGSize(width: 75, height: 50))
        enemy.name = "enemy"

        // Spawn on the right, random Y
        let randomY = CGFloat.random(in: enemy.size.height/2...(sceneSize.height - enemy.size.height/2))
        enemy.position = CGPoint(x: sceneSize.width + enemy.size.width / 2, y: randomY)

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
        let moveAction = SKAction.moveBy(x: -(self.scene!.size.width + self.size.width), y: 0, duration: (self.scene!.size.width + self.size.width) / Constants.enemySpeed)
        let removeAction = SKAction.removeFromParent()
        self.run(SKAction.sequence([moveAction, removeAction]))
    }
}

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
