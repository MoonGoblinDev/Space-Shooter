import SpriteKit

class ExplosionNode {
    static func showExplosion(at position: CGPoint, in scene: SKScene) {
        if let explosionEmitter = SKEmitterNode(fileNamed: "Explosion.sks") {
            explosionEmitter.position = position
            explosionEmitter.zPosition = Constants.ZPositions.projectile + 0.2 // Higher than projectiles
            scene.addChild(explosionEmitter)

            // Calculate duration for the explosion effect to complete
            // This is an estimate; adjust based on your particle settings
            let estimatedExplosionDuration = explosionEmitter.particleLifetime + explosionEmitter.particleLifetimeRange / 2 + 0.3 // Add buffer
            
            let waitAction = SKAction.wait(forDuration: TimeInterval(estimatedExplosionDuration))
            let removeAction = SKAction.removeFromParent()
            explosionEmitter.run(SKAction.sequence([waitAction, removeAction]))
        } else {
            print("Error: Could not load Explosion.sks")
        }
    }
}
