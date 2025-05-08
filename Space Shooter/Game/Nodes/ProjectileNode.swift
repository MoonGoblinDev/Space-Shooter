// Space Shooter/Game/Nodes/ProjectileNode.swift
import SpriteKit

enum ProjectileType {
    case player
    case enemy
}

class ProjectileNode: SKNode {

    var type: ProjectileType
    private(set) var emitter: SKEmitterNode?
    private var visualSize: CGSize = .zero // Store the size of the visual element

    static func newInstance(type: ProjectileType, initialVisualSize: CGSize = CGSize(width: 5, height: 5)) -> ProjectileNode {
        let projectile = ProjectileNode(type: type, visualSize: initialVisualSize)
        projectile.name = "projectile_\(type)"

        var emitterFileName: String
        var defaultColor: SKColor = .yellow // Fallback color

        switch type {
        case .player:
            emitterFileName = "Laser 1.sks"
            defaultColor = .cyan
        case .enemy:
            emitterFileName = "EnemyProjectile.sks" // User specified this file name
            defaultColor = .red
        }

        if let emitterNode = SKEmitterNode(fileNamed: emitterFileName) {
            projectile.addChild(emitterNode)
            projectile.emitter = emitterNode
            // If the particle system itself has a size, use that. Otherwise, it's more abstract.
            // For physics body, we use 'initialVisualSize' passed in.
            // Ensure emitter particles are emitted along the projectile's movement axis.
            // If particles shoot "up" from the sks file, and projectile moves horizontally:
            // emitterNode.zRotation = -CGFloat.pi / 2 for right, or CGFloat.pi / 2 for left
            if type == .enemy {
                 emitterNode.zRotation = CGFloat.pi // Assuming EnemyProjectile.sks emits to the right by default
            }

        } else {
            print("Error: Could not load \(emitterFileName). Using fallback visual for projectile type \(type).")
            let fallbackVisual = SKSpriteNode(color: defaultColor, size: initialVisualSize)
            projectile.addChild(fallbackVisual)
        }
        // Use the provided initialVisualSize for the physics body extent
        projectile.physicsBody = SKPhysicsBody(rectangleOf: initialVisualSize)
        projectile.physicsBody?.isDynamic = true // Will be false if using kinematic movement via actions
        projectile.physicsBody?.affectedByGravity = false
        projectile.physicsBody?.categoryBitMask = Constants.PhysicsCategory.projectile
        projectile.physicsBody?.collisionBitMask = Constants.PhysicsCategory.none

        switch type {
        case .player:
            projectile.physicsBody?.contactTestBitMask = Constants.PhysicsCategory.enemy | Constants.PhysicsCategory.asteroid
        case .enemy:
            projectile.physicsBody?.contactTestBitMask = Constants.PhysicsCategory.player
        }
        
        projectile.zPosition = Constants.ZPositions.projectile

        return projectile
    }

    private init(type: ProjectileType, visualSize: CGSize) {
        self.type = type
        self.visualSize = visualSize
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func launch(from startPoint: CGPoint, initialVelocity: CGVector, scene: SKScene) {
        self.position = startPoint
        scene.addChild(self)

        // Apply an impulse to start the physics-based movement
        self.physicsBody?.isDynamic = true // Ensure it's dynamic for velocity to work
        self.physicsBody?.velocity = initialVelocity

        // Add an action to remove the projectile if it goes too far off-screen
        // This acts as a failsafe if it doesn't collide with anything.
        let lifetime: TimeInterval = 3.0 // Projectile lives for 3 seconds if it doesn't hit anything
        let removeAction = SKAction.sequence([
            SKAction.wait(forDuration: lifetime),
            SKAction.run { [weak self] in
                // If it's still in the scene, detonate (which also removes it)
                // This handles projectiles that miss and fly off-screen.
                self?.detonate(offScreen: true)
            }
        ])
        self.run(removeAction, withKey: "projectileLifetime")
    }

    func detonate(offScreen: Bool = false) {
        self.physicsBody = nil // Stop further physics interactions
        self.removeAllActions() // Stop lifetime action or other movement actions

        var explosionPositionInScene = self.position
        if let currentScene = self.scene, self.parent != currentScene && self.parent != nil {
            explosionPositionInScene = currentScene.convert(self.position, from: self.parent!)
        }

        // Stop existing laser particles from emitting new ones
        if let laserEmitter = self.emitter {
            laserEmitter.particleBirthRate = 0
            let laserFadeOutDuration = TimeInterval(laserEmitter.particleLifetime + laserEmitter.particleLifetimeRange / 2)
            
            laserEmitter.run(SKAction.sequence([
                SKAction.wait(forDuration: laserFadeOutDuration + 0.1), // Wait for existing particles to die
                SKAction.removeFromParent() // Remove just the emitter
            ]))
        } else {
            // If only a fallback visual, remove its children (the fallback sprite)
             self.children.forEach { $0.removeFromParent() }
        }
        
        // Don't show explosion if it just went off-screen silently
        if !offScreen, let scene = self.scene {
            if let explosionEmitter = SKEmitterNode(fileNamed: "ProjectileExplode.sks") {
                explosionEmitter.position = explosionPositionInScene
                explosionEmitter.zPosition = Constants.ZPositions.projectile + 0.1
                scene.addChild(explosionEmitter)

                let estimatedExplosionDuration = TimeInterval(explosionEmitter.particleLifetime + explosionEmitter.particleLifetimeRange / 2 + 0.3)
                explosionEmitter.run(SKAction.sequence([
                    SKAction.wait(forDuration: estimatedExplosionDuration),
                    SKAction.removeFromParent()
                ]), withKey: "explosionCleanup")
            } else {
                print("Error: Could not load ProjectileExplode.sks.")
            }
        }
        
        // Remove the main ProjectileNode itself after a short delay to let emitter fade if it was very short-lived
        let removalDelay = (self.emitter != nil && !offScreen) ? 0.5 : 0.01
        self.run(SKAction.sequence([
            SKAction.wait(forDuration: removalDelay),
            SKAction.removeFromParent()
        ]))
    }
}
