import SpriteKit

class ExplosionNode {
    static func showExplosion(at position: CGPoint, in scene: SKScene) {
        if let explosionEmitter = SKEmitterNode(fileNamed: "Explosion.sks") {
            explosionEmitter.position = position
            explosionEmitter.zPosition = Constants.ZPositions.projectile + 0.2
            scene.addChild(explosionEmitter)

            // Calculate duration for the explosion effect to complete

            let estimatedExplosionDuration = explosionEmitter.particleLifetime + explosionEmitter.particleLifetimeRange / 2 + 0.3 
            
            let waitAction = SKAction.wait(forDuration: TimeInterval(estimatedExplosionDuration))
            let removeAction = SKAction.removeFromParent()
            explosionEmitter.run(SKAction.sequence([waitAction, removeAction]))
        } else {
            print("Error: Could not load Explosion.sks")
        }
    }
}
