import SpriteKit

enum ProjectileType {
    case player
    case enemy // If you add enemy projectiles later
}

class ProjectileNode: SKNode { // Changed from SKSpriteNode to SKNode

    var type: ProjectileType
    private(set) var emitter: SKEmitterNode?

    // The size parameter is now for the physics body, not necessarily the visual
    static func newInstance(type: ProjectileType, size: CGSize = CGSize(width: 5, height: 5)) -> ProjectileNode {
        let projectile = ProjectileNode(type: type, initialSize: size)
        projectile.name = "projectile_\(type)"

        // 1. Load the SKEmitterNode from the .sks file
        if let emitter = SKEmitterNode(fileNamed: "Laser 1.sks") {
            projectile.addChild(emitter)
            projectile.emitter = emitter
            // Optional: If your emitter's particles shoot out in a direction other than what you want
            // relative to the projectile's movement, you can adjust its zRotation.
            // e.g., if particles naturally shoot up, but projectile moves right:
            // emitter.zRotation = -CGFloat.pi / 2
            
            // The emitter's targetNode determines where particles are rendered relative to.
            // Setting it to the scene makes particles appear more "detached" from the projectile
            // if the projectile moves very fast. For a laser attached to the projectile,
            // keeping it as a child and not setting targetNode explicitly is usually best.
            // emitter.targetNode = projectile.scene // Experiment if needed
        } else {
            print("Error: Could not load LaserEffect.sks")
            // Fallback visual if particle fails to load (optional)
            let fallbackVisual = SKSpriteNode(color: .yellow, size: size)
            projectile.addChild(fallbackVisual)
        }

        // 2. Setup Physics Body (attached to the ProjectileNode itself)
        projectile.physicsBody = SKPhysicsBody(rectangleOf: size)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.affectedByGravity = false
        projectile.physicsBody?.categoryBitMask = Constants.PhysicsCategory.projectile
        projectile.physicsBody?.collisionBitMask = Constants.PhysicsCategory.none // Projectiles don't physically collide with each other

        switch type {
        case .player:
            projectile.physicsBody?.contactTestBitMask = Constants.PhysicsCategory.enemy | Constants.PhysicsCategory.asteroid
        case .enemy:
            projectile.physicsBody?.contactTestBitMask = Constants.PhysicsCategory.player
            // Potentially different particle effect or color for enemy projectiles
        }
        
        projectile.zPosition = Constants.ZPositions.projectile

        return projectile
    }

    // Private initializer
    private init(type: ProjectileType, initialSize: CGSize) {
        self.type = type
        super.init() // SKNode's designated initializer
        // Note: We don't set a texture or color here for the SKNode base.
        // The physics body size is what matters for the SKNode's "extent".
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Call this when the projectile hits something or should be removed
    // In ProjectileNode.swift

    func detonate() {
        // --- 1. Capture current position for the explosion ---
        // It's best to capture the position in scene coordinates *before* any nodes are removed.
        // This assumes the ProjectileNode is a direct child of the scene when detonate() is called.
        // If it's nested deeper, this conversion might need to be more complex or handled by GameScene.
        var explosionPositionInScene: CGPoint? = nil
        if let currentScene = self.scene {
            // If self.parent is currentScene, then self.position is already in scene coordinates (relative to anchor).
            // If self.parent is something else (which is not the case here if added directly to scene),
            // you'd convert: explosionPositionInScene = currentScene.convert(self.position, from: self.parent!)
            explosionPositionInScene = self.position // Assuming self.parent is the scene itself or its anchor isn't (0,0)
                                                    // More robust: self.scene?.convert(self.position, from: self.parent ?? self.scene!) ?? self.position
                                                    // For simplicity with current setup:
            if self.parent != currentScene && self.parent != nil { // If projectile is nested
                 explosionPositionInScene = currentScene.convert(self.position, from: self.parent!)
            } else { // Projectile is direct child of scene
                explosionPositionInScene = self.position
            }
        }

        // --- 2. Handle the original laser emitter (self.emitter) ---
        if let laserEmitter = self.emitter {
            laserEmitter.particleBirthRate = 0 // Stop emitting new laser particles
            
            // Calculate duration for existing laser particles to fade out.
            // This should be based on the LaserEffect.sks settings.
            // Ensure emitter.particleLifetime and emitter.particleLifetimeRange are giving sensible values.
            let laserFadeOutDuration = 0.01
            
            let waitLaserParticlesAction = SKAction.wait(forDuration: laserFadeOutDuration)
            let removeProjectileNodeAction = SKAction.removeFromParent() // This removes the ProjectileNode itself
            
            // Run the sequence on the ProjectileNode (self)
            self.run(SKAction.sequence([waitLaserParticlesAction, removeProjectileNodeAction]))
            
        } else {
            // If there's no laser emitter, the ProjectileNode itself can be removed immediately.
            self.removeFromParent()
        }

        // --- 3. Spawn the "Detonate.sks" particle effect ---
        // This happens regardless of whether there was a laser emitter.
        // We use the captured `explosionPositionInScene`.
        if let scene = self.scene, let validExplosionPosition = explosionPositionInScene {
            if let explosionEmitter = SKEmitterNode(fileNamed: "ProjectileExplode.sks") {
                explosionEmitter.position = validExplosionPosition

                explosionEmitter.zPosition = Constants.ZPositions.projectile + 0.1 // Ensure it's visible, slightly above projectiles

                // Add the explosion emitter to the scene
                scene.addChild(explosionEmitter)


                // The explosion emitter should remove itself after its effect is done.
                // Calculate its duration based on its *own* particle lifetime + a small buffer.
                // This assumes Detonate.sks particles have a defined lifetime and the emitter isn't set to loop infinitely.
                // Add a buffer (e.g., 0.2s) to ensure all particles visually complete.
                
                let estimatedExplosionDuration = 0.3
                let waitExplosionAction = SKAction.wait(forDuration: estimatedExplosionDuration)
                let removeExplosionNodeAction = SKAction.removeFromParent()
                explosionEmitter.run(SKAction.sequence([waitExplosionAction, removeExplosionNodeAction]), withKey: "explosionCleanup")
            } else {
                print("Error: Could not load Detonate.sks. Make sure the file is in your project, target, and the name is correct.")
            }
        } else {
            // This case might occur if the scene became nil very quickly,
            // or if explosionPositionInScene couldn't be determined.
            print("Warning: Could not get scene or valid position to spawn Detonate.sks effect for projectile.")
        }
    }
}
