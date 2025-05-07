import Foundation

struct Constants {
    struct PhysicsCategory {
        static let none         : UInt32 = 0
        static let all          : UInt32 = UInt32.max
        static let player       : UInt32 = 0b1       // 1
        static let enemy        : UInt32 = 0b10      // 2
        static let asteroid     : UInt32 = 0b100     // 4
        static let projectile   : UInt32 = 0b1000    // 8
        // Add HealthItem later: static let healthItem : UInt32 = 0b10000 // 16
    }

    struct ZPositions {
        static let background   : CGFloat = -1.0
        static let asteroid     : CGFloat = 0.0
        static let enemy        : CGFloat = 0.5 // Enemies slightly above asteroids if they overlap
        static let projectile   : CGFloat = 1.0
        static let player       : CGFloat = 2.0
        static let hud          : CGFloat = 10.0
    }

    static let playerSpeed: CGFloat = 250.0
    static let projectileSpeed: CGFloat = 500.0
    static let enemySpeed: CGFloat = 150.0
    static let asteroidSpeed: CGFloat = 100.0

    static let playerShootCooldown: TimeInterval = 0.3
    static let playerInitialHealth: Int = 3
    
    static let enemySpawnInterval: TimeInterval = 1.5
    static let asteroidSpawnInterval: TimeInterval = 2.5
}
