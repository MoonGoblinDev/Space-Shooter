import SpriteKit

class AsteroidNode: SKSpriteNode {
    // For now, asteroids are destroyed in one hit by player projectile or collision
    static func newInstance(sizeRange:(min:CGFloat, max:CGFloat), sceneSize: CGSize) -> AsteroidNode {
        let actualSize = CGFloat.random(in: sizeRange.min...sizeRange.max)
        
        let shapeNode = SKShapeNode(circleOfRadius: actualSize / 2)
        shapeNode.fillColor = .gray
        shapeNode.strokeColor = .darkGray
        shapeNode.lineWidth = 2
        
        let textureList = ["Asteroid 1", "Asteroid 2", "Asteroid 3"]

        let texture = SKTexture(imageNamed: textureList.randomElement()!)
        let asteroid = AsteroidNode(texture: texture, color: .clear, size: CGSize(width: actualSize, height: actualSize))
        asteroid.name = "asteroid"
        
        // Spawn on the right, random Y
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
        // Give asteroids a bit of random spin
        let randomRotation = CGFloat.random(in: -1.0...1.0) * .pi * 2 // up to one full rotation
        let rotateAction = SKAction.rotate(byAngle: randomRotation, duration: 5.0) // Spin over 5 seconds
        self.run(SKAction.repeatForever(rotateAction))

        let moveAction = SKAction.moveBy(x: -(self.scene!.size.width + self.size.width), y: 0, duration: (self.scene!.size.width + self.size.width) / Constants.asteroidSpeed)
        let removeAction = SKAction.removeFromParent()
        self.run(SKAction.sequence([moveAction, removeAction]))
    }
}
