import SpriteKit

class AsteroidNode: SKSpriteNode, Damageable {
    var health: Int = Constants.asteroidInitialHealth

    static func newInstance(sizeRange:(min:CGFloat, max:CGFloat), sceneSize: CGSize) -> AsteroidNode {
        let actualSize = CGFloat.random(in: sizeRange.min...sizeRange.max)
        
        let asteroidSprites: [String] = ["Asteroid 1", "Asteroid 2", "Asteroid 3"]
        let texture = SKTexture(imageNamed: asteroidSprites.randomElement()!)
        let asteroid = AsteroidNode(texture: texture, color: .clear, size: CGSize(width: actualSize, height: actualSize))
        asteroid.name = "asteroid"
        
        let randomY = CGFloat.random(in: asteroid.size.height/2...(sceneSize.height - asteroid.size.height/2))
        asteroid.position = CGPoint(x: sceneSize.width + asteroid.size.width / 2, y: randomY)

        asteroid.physicsBody = SKPhysicsBody(circleOfRadius: asteroid.size.width / 2)
        asteroid.physicsBody?.isDynamic = true
        asteroid.physicsBody?.affectedByGravity = false
        asteroid.physicsBody?.categoryBitMask = Constants.PhysicsCategory.asteroid
        asteroid.physicsBody?.contactTestBitMask = Constants.PhysicsCategory.projectile | Constants.PhysicsCategory.player
        asteroid.physicsBody?.collisionBitMask = Constants.PhysicsCategory.none
        asteroid.zPosition = Constants.ZPositions.asteroid
        
        return asteroid
    }
    
    func startMoving() {
        let randomRotation = CGFloat.random(in: -1.0...1.0) * .pi * 2
        let rotateAction = SKAction.rotate(byAngle: randomRotation, duration: 5.0)
        self.run(SKAction.repeatForever(rotateAction))

        let moveAction = SKAction.moveBy(x: -(self.scene!.size.width + self.size.width), y: 0, duration: (self.scene!.size.width + self.size.width) / Constants.asteroidSpeed)
        let removeAction = SKAction.removeFromParent() 
        self.run(SKAction.sequence([moveAction, removeAction]), withKey: "movement")
    }

    // MARK: - Damageable
    func takeDamage(amount: Int, in scene: SKScene?) {
        health -= amount
        
        if health > 0 {
            animateDamage(tintRed: false, shakeIntensity: 6.0)
        } else {
            self.removeAction(forKey: "movement")
            explode(in: scene)
        }
    }
}
