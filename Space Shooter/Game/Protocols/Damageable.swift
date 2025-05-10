import SpriteKit

protocol Damageable: AnyObject {
    var health: Int { get set }
    func takeDamage(amount: Int, in scene: SKScene?)
    func animateDamage(tintRed: Bool, shakeIntensity: CGFloat)
    func explode(in scene: SKScene?)
}

extension Damageable where Self: SKNode {
    // Default implementation for animating damage
    func animateDamage(tintRed: Bool, shakeIntensity: CGFloat = 5.0) {
        // Shake animation
        let moveRight = SKAction.moveBy(x: shakeIntensity, y: 0, duration: 0.05)
        let moveLeft = SKAction.moveBy(x: -shakeIntensity * 2, y: 0, duration: 0.1)
        let moveCenter = SKAction.moveBy(x: shakeIntensity, y: 0, duration: 0.05)
        let shakeAction = SKAction.sequence([moveRight, moveLeft, moveCenter, moveRight, moveLeft, moveCenter]) 
        
        var actions: [SKAction] = [shakeAction]

        if tintRed {
            let tintAction = SKAction.colorize(with: .red, colorBlendFactor: 0.8, duration: 0.1)
            let untintAction = SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.1)
            let damageFlash = SKAction.sequence([tintAction, .wait(forDuration: 0.1), untintAction])
            actions.append(damageFlash)
        }
        
        self.run(SKAction.group(actions)) // Run shake and tint concurrently
    }

    func explode(in scene: SKScene?) {
        guard let currentScene = scene ?? self.scene else {
            self.removeFromParent() // Fallback if scene cannot be determined
            return
        }
        
        ExplosionNode.showExplosion(at: self.position, in: currentScene)
        self.removeFromParent()
    }
}
