## Space Shooter: Project Documentation

This document outlines the structure and functionality of the Space Shooter game, with a particular focus on how Apple's SpriteKit framework is utilized.

### 1. Project Overview

Space Shooter is a 2D horizontal scrolling game where the player controls a spaceship on the left side of the screen. Enemies and asteroids spawn from the right, and the player's objective is to shoot them down, avoid collisions, and achieve a high score. The game is controlled via keyboard input.

The game is built using **SpriteKit**, Apple's framework for creating 2D games and graphics-intensive applications. SpriteKit provides a powerful rendering engine, physics simulation, particle effects, and tools for managing game scenes and nodes.

The project is organized into several key directories:
*   `Scenes/`: Contains different game states like `MenuScene`, `GameScene`, and `GameOverScene`.
*   `Nodes/`: Contains custom `SKNode` subclasses representing game entities like `PlayerNode`, `EnemyNode`, etc.
*   `Protocols/`: Defines shared behaviors for game entities (e.g., `Damageable`).
*   `Utils/`: Contains helper files like `Constants.swift`.

### 2. Core Application Setup

#### `AppDelegate.swift`
This file contains the standard `AppDelegate` class for a macOS application.
*   `applicationDidFinishLaunching(_:)`: Called when the application has finished launching and is ready to run. It's a common place for initial application-wide setup. In this project, it's currently empty, meaning no special initialization is done at this very early stage.
*   `applicationWillTerminate(_:)`: Called when the application is about to terminate. Useful for cleanup tasks. Also empty in this project.

**SpriteKit Relevance:** The `AppDelegate` itself doesn't directly interact with SpriteKit, but it sets up the application environment in which the `ViewController` and subsequently the `SKView` will operate.

#### `ViewController.swift`
This `NSViewController` subclass is responsible for setting up and managing the `SKView`, which is the view that renders SpriteKit content.

*   **`viewDidLoad()`**:
    *   Casts the controller's main view to an `SKView`. `SKView` is a specialized `NSView` (on macOS) or `UIView` (on iOS) that renders SpriteKit scenes.
    *   **Scene Initialization**: It creates an instance of `MenuScene`, passing the view's bounds as its size. This ensures the scene initially matches the window size.
    *   `menuScene.scaleMode = .resizeFill`: This SpriteKit property determines how the scene's content is scaled to fit the `SKView`. `.resizeFill` stretches the scene to fill the view, potentially altering the aspect ratio. Other options include `.aspectFill` (maintains aspect ratio, fills the view, potentially cropping) and `.aspectFit` (maintains aspect ratio, fits within the view, potentially leaving letterbox/pillarbox bars).
    *   `view.presentScene(menuScene)`: This crucial `SKView` method displays the `MenuScene`. SpriteKit handles the rendering loop for the presented scene.
    *   `view.ignoresSiblingOrder = true`: An optimization hint for SpriteKit. When true, SpriteKit may reorder nodes at the same `zPosition` for better rendering performance, but this means explicit z-ordering is crucial if visual layering is important.
    *   Debugging properties (`showsFPS`, `showsNodeCount`, `showsPhysics`) are commented out but are invaluable during development for diagnosing performance and physics issues.

*   **`viewDidLayout()`**:
    *   This method is called when the view's bounds change (e.g., window resize).
    *   It ensures that the `SKScene`'s `size` property is updated to match the new `SKView` bounds. This allows the scene content to adapt to different window sizes dynamically if the scene logic supports it (e.g., by repositioning elements based on `self.size`).

**SpriteKit Relevance:** `ViewController` acts as the bridge between the macOS application structure and the SpriteKit world. Its primary role here is to create, configure, and display the `SKView` and present the initial `SKScene`.

### 3. Game Scenes

Scenes in SpriteKit are represented by `SKScene` objects. Each scene is like a distinct screen or level in your game. It's the root node of a tree of `SKNode` objects that represent all visible (and some invisible) elements.

#### `MenuScene.swift`
This scene serves as the main menu of the game.

*   **`didMove(to view: SKView)`**: This `SKScene` lifecycle method is called immediately after a scene is presented by an `SKView`. It's the primary setup point for the scene's content.
    *   Sets `backgroundColor` and `anchorPoint`. An `anchorPoint` of `(0.5, 0.5)` means the scene's coordinate system origin `(0,0)` is at the center of the view.
    *   Calls `setupStaticBackground()` and `setupUIElements()`.
*   **`setupStaticBackground()`**:
    *   Creates a single `SKSpriteNode` for the background using an image named "Nebula Blue".
    *   `backgroundTexture.filteringMode = .linear`: This tells SpriteKit to use linear filtering when scaling the texture, which can result in a smoother appearance for static backgrounds compared to `.nearest`.
    *   The background node's size is calculated to fill the entire_scene_ (aspect fill behavior), ensuring no letterboxing, by comparing the scene's aspect ratio to the texture's aspect ratio.
    *   `bgNode.position = CGPoint.zero`: Since the scene's anchor point is `(0.5, 0.5)`, `(0,0)` is the center.
    *   `bgNode.zPosition = Constants.ZPositions.background`: Sets the drawing order. Lower z-positions are drawn first (further back).
*   **`setupUIElements()`**:
    *   Creates `SKLabelNode` instances for the game title ("Space Shooter") and an instruction ("Press Enter to Play"). `SKLabelNode` is SpriteKit's way to display text.
    *   The instruction label has a repeating fade-in/fade-out animation using `SKAction.sequence` and `SKAction.repeatForever`. `SKAction`s are powerful tools for animating node properties over time.
    *   A `PlayerNode` instance is created for decorative purposes, with its physics body removed and thruster always active.
    *   Calls `updateUIPositions()` to arrange these elements.
*   **`updateUIPositions()`**: Positions the title, static player, and instruction label relative to the scene's size (e.g., `size.height * 0.25`). This helps with basic responsiveness.
*   **`keyDown(with event: NSEvent)`**: Handles keyboard input. If Enter or Return is pressed, it calls `startGame()`.
*   **`startGame()`**:
    *   Creates an instance of `GameScene`.
    *   `gameScene.scaleMode = self.scaleMode`: Passes the current scene's scale mode to the new scene for consistency.
    *   Uses `SKTransition.fade(withDuration: 1.0)` to create a smooth visual transition between scenes.
    *   `view.presentScene(gameScene, transition: transition)` displays the `GameScene`.
*   **`didChangeSize(_ oldSize: CGSize)`**: Called when the scene's size changes (typically due to window resize). It re-runs `setupStaticBackground()` and `updateUIPositions()` to adapt the layout.

**SpriteKit Relevance:** `MenuScene` demonstrates:
*   Scene setup (`didMove(to:)`).
*   Use of `SKSpriteNode` for backgrounds and `SKLabelNode` for text.
*   Basic animations with `SKAction`.
*   Event handling for keyboard input (`keyDown`).
*   Scene transitions (`SKTransition`).
*   Layout adaptation (`didChangeSize`, `updateUIPositions`).

#### `GameScene.swift`
This is the heart of the game, where actual gameplay occurs.

*   **Properties**:
    *   `player: PlayerNode!`: Reference to the player's spaceship.
    *   `scoreLabel: SKLabelNode!`, `healthNodes: [SKSpriteNode]`: UI elements for displaying score and player health (using heart sprites).
    *   `score: Int`: Tracks the player's score. The `didSet` property observer automatically updates `scoreLabel.text`.
    *   `keysPressed = Set<UInt16>()`: Stores currently pressed keyboard keys for smooth, continuous movement.
    *   `backgroundNodes: [SKSpriteNode]`: An array to manage multiple background segments for the scrolling effect.
*   **`didMove(to view: SKView)`**:
    *   Sets `backgroundColor`, `physicsWorld.gravity = .zero` (as it's a space game), and `physicsWorld.contactDelegate = self` to enable collision detection callbacks.
    *   `anchorPoint = CGPoint(x: 0, y: 0)`: Sets the scene origin to the bottom-left corner. This is a common choice for side-scrollers, making coordinate calculations based on scene width/height more direct.
    *   Calls setup methods: `preloadHeartTextures()`, `setupScrollingBackground()`, `setupPlayer()`, `setupUI()`, and `startSpawning()`.
*   **Texture Preloading (`preloadHeartTextures()`)**:
    *   Uses `NSImage(systemSymbolName:...)` to get SF Symbols ("heart.fill", "heart").
    *   `image.isTemplate = true`: Allows the SF Symbol to be tinted.
    *   The `tinted(with:)` extension (defined at the end of the file) creates new `NSImage` instances tinted red (for full) and gray (for empty).
    *   `SKTexture(image:)` converts these `NSImage`s into `SKTexture`s for use with `SKSpriteNode`. This preloading avoids potential hitches during gameplay when these textures are first needed.
*   **`setupScrollingBackground()`**:
    *   Creates multiple `SKSpriteNode` instances using the "Nebula Blue" texture.
    *   The width of each background segment (`individualBackgroundWidth`) is calculated based on the scene's height and the texture's aspect ratio to maintain proportions.
    *   Segments are positioned side-by-side to create a continuous background.
*   **`setupPlayer()`**:
    *   Creates a `PlayerNode` instance and positions it on the left side of the scene.
    *   Adds the player to the scene graph using `addChild(player)`.
*   **`setupUI()`**:
    *   Initializes `scoreLabel` (`SKLabelNode`).
    *   Creates `SKSpriteNode`s for health indicators (hearts) using the preloaded `fullHeartTexture`.
    *   Calls `updateUIPositions()` and `updateHealthUI()` to position and set the initial state of UI elements.
*   **`updateUIPositions()`**: Positions the `scoreLabel` at the top-left and `healthNodes` at the top-right, considering margins defined in `Constants`.
*   **`updateHealthUI()`**: Iterates through `healthNodes`. If the node's index is less than the player's current health, it shows a `fullHeartTexture`; otherwise, it shows an `emptyHeartTexture` (or a faded full heart as a fallback).
*   **Spawning Logic (`startSpawning()`, `spawnEnemy()`, `spawnAsteroid()`)**:
    *   `startSpawning()`: Uses `SKAction.sequence` and `SKAction.repeatForever` to repeatedly call `spawnEnemy()` and `spawnAsteroid()` at intervals defined in `Constants`. `run(action, withKey:)` allows these repeating actions to be identified and potentially stopped later.
    *   `spawnEnemy()` / `spawnAsteroid()`: Creates new `EnemyNode` or `AsteroidNode` instances, adds them to the scene, and calls their respective `startMoving()` (and `startShooting()` for enemies).
*   **Input Handling (`keyDown(with:)`, `keyUp(with:)`)**:
    *   `keyDown`: Adds the `event.keyCode` to the `keysPressed` set. If the spacebar (keyCode 49) is pressed, it calls `player.shoot()`.
    *   `keyUp`: Removes the `event.keyCode` from `keysPressed`.
*   **Game Loop (`update(_ currentTime: TimeInterval)`)**:
    *   Called by SpriteKit approximately 60 times per second.
    *   Calculates `deltaTime` (time since the last update) for frame-rate independent movement and logic. It caps `deltaTime` to avoid large jumps if the game stalls.
    *   Calls `scrollBackground()` and `processPlayerMovement()`.
    *   Updates the player's thruster visual based on whether movement keys are pressed.
*   **`scrollBackground(deltaTime:)`**:
    *   Moves each background node in `backgroundNodes` to the left.
    *   If a background segment moves completely off-screen to the left, it's repositioned to the right end of the entire background strip, creating an infinite scrolling illusion.
*   **`processPlayerMovement(deltaTime:)`**:
    *   Checks the `keysPressed` set to determine movement direction.
    *   Calculates new player position based on `Constants.playerSpeed` and `deltaTime`.
    *   Clamps the player's position to keep them within the scene boundaries.
*   **Physics Contact Handling (`didBegin(_ contact: SKPhysicsContact)`)**:
    *   This method from `SKPhysicsContactDelegate` is called when two physics bodies with appropriate `contactTestBitMask`s begin to overlap.
    *   It determines which two types of nodes have collided (e.g., player projectile with enemy, player with asteroid) by checking their `categoryBitMask`.
    *   Calls specific handler methods like `projectileDidCollideWithEnemy()`, `playerDidCollideWithObstacle()`, etc.
    *   These handlers typically:
        *   Tell the projectile to `detonate()`.
        *   Apply damage to the collided entity (`takeDamage(amount:in:)`).
        *   Update the score if an enemy is destroyed.
        *   If a player collides with an obstacle, both take damage.
*   **`gameOver()`**:
    *   Sets `isGameOverPending = true` to prevent further game actions.
    *   Stops all scene actions and clears `keysPressed`.
    *   Iterates through active enemies and asteroids using `enumerateChildNodes(withName:)` to stop their actions. `SKNode.name` is useful for finding specific nodes.
    *   Removes the player node after showing an explosion.
    *   Uses an `SKAction.sequence` with a delay to transition to `GameOverScene` using `SKTransition.doorsCloseHorizontal`.
*   **`didChangeSize(_ oldSize: CGSize)`**: Adapts to scene size changes by re-running `setupScrollingBackground()` and `updateUIPositions()`, and re-clamping player position.
*   **`NSImage` Extension (`tinted(with:)`)**: A helper method to create a new `NSImage` by tinting an existing one with a specified color. This is used for the heart UI elements, allowing SF Symbols (which can act as templates) to be colored dynamically.

**SpriteKit Relevance:** `GameScene` is where most SpriteKit features come together:
*   Scene lifecycle and setup.
*   Node management (`addChild`, `removeFromParent`, `enumerateChildNodes`).
*   Texture loading (`SKTexture`).
*   Physics simulation (`SKPhysicsWorld`, `SKPhysicsContactDelegate`, `SKPhysicsBody`).
*   Actions (`SKAction` for spawning, timed events, animations, sequences).
*   Particle effects (via `ExplosionNode` and nodes like `PlayerNode`).
*   User input handling.
*   The game loop (`update`).
*   Camera/View concepts (scrolling background).
*   Scene transitions.
*   Working with node names for identification.

#### `GameOverScene.swift`
Displayed when the player's health reaches zero.

*   **`init(size: CGSize, score: Int)`**: Custom initializer to pass the final score from `GameScene`.
*   **`didMove(to view: SKView)`**:
    *   Sets up background and UI elements (`SKLabelNode` for "Game Over" title, final score, and "Back to Menu" button).
    *   UI elements are initially hidden (`isHidden = true`, `alpha = 0`).
    *   An `SKAction.sequence` with a `wait` and a `run` block is used to delay the appearance of UI elements, which then fade in.
*   **`setupBackground()`**: Similar to `MenuScene`, sets up a static background ("Gate" texture), ensuring it fills the screen while maintaining aspect ratio.
*   **UI Setup (`setupGameOverTitle`, `setupScoreLabel`, `setupBackButton`)**: Creates and positions `SKLabelNode`s. The "Back to Menu" button is given a `name` property ("backButton") for easy identification in touch/mouse handling.
*   **Input Handling (`keyDown(with:)`, `mouseDown(with:)`)**:
    *   `keyDown`: Listens for Enter/Return to go back to the menu.
    *   `mouseDown`: Checks if the click location hits the node named "backButton". `nodes(at: location)` returns an array of all nodes at that point.
*   **`backToMenu()`**: Transitions back to `MenuScene` using a fade transition.
*   **`didChangeSize(_ oldSize: CGSize)`**: Re-setups the background and re-positions UI elements when the scene size changes.

**SpriteKit Relevance:**
*   Displaying information using `SKLabelNode`.
*   Using `SKAction` for delayed animations (fade-in).
*   Handling mouse input (`mouseDown`) and node identification using `node.name`.
*   Scene transitions.

### 4. Game Entities (Nodes)

Game entities are typically subclasses of `SKNode` or `SKSpriteNode`.

#### `PlayerNode.swift`
Represents the player's spaceship.

*   **Conforms to `Damageable`**: Implements health and damage-taking logic.
*   **`health: Int`**: Player's health. The `didSet` observer calls `scene.updateHealthUI()` to refresh the health display in `GameScene`.
*   **`static func newInstance(size: CGSize)`**: A factory method to create and configure a new player node.
    *   Loads texture "Spaceship 1" into an `SKTexture`.
    *   Creates an `SKSpriteNode` with this texture.
    *   **Physics Body**: `SKPhysicsBody(texture: player.texture!, size: player.size)` creates a physics body that matches the shape of the player's texture.
        *   `isDynamic = true`: The physics body is affected by forces and can move.
        *   `affectedByGravity = false`: Ignores scene gravity.
        *   `categoryBitMask = Constants.PhysicsCategory.player`: Assigns a category for collision detection.
        *   `contactTestBitMask`: Defines which other categories will trigger a contact event with the player (enemies, asteroids).
        *   `collisionBitMask = Constants.PhysicsCategory.none`: The player will not physically push or be pushed by other objects; collisions are handled via contact events only.
    *   `zPosition`: Sets drawing order.
    *   `setupThruster()`: Initializes the thruster particle effect.
*   **`shoot(currentTime: TimeInterval, scene: SKScene)`**:
    *   Implements a shooting cooldown (`Constants.playerShootCooldown`).
    *   Creates a `ProjectileNode` of type `.player`.
    *   Positions the projectile to fire from the front-right of the player.
    *   Launches the projectile using its `launch(...)` method.
*   **`takeDamage(amount: Int, in scene: SKScene?)`**:
    *   Reduces health.
    *   Calls `animateDamage()` (from `Damageable` extension) for visual feedback.
    *   If health is zero or less, calls `gameScene.gameOver()`.
*   **`explode(in scene: SKScene?)`**: Default implementation from `Damageable` is likely used, or it could be overridden for player-specific explosion behavior (though `gameOver()` in `GameScene` handles the main player destruction visual).
*   **`setupThruster()` & `updateThruster(isMoving: Bool)`**:
    *   `setupThruster()`: Loads an `SKEmitterNode` from "ThrusterEffect.sks" (a SpriteKit Particle Editor file) and adds it as a child to the player. `SKEmitterNode` automatically renders particle animations.
    *   `didMoveToScene()`: Sets the `targetNode` of the emitter to the scene. This is important for particles to be rendered correctly relative to the scene if the emitter is part of a moving node hierarchy that might be transformed.
    *   `updateThruster()`: Adjusts `particleBirthRate` of the emitter to make the thruster more intense when moving.

**SpriteKit Relevance:**
*   `SKSpriteNode` for visual representation.
*   `SKTexture` for images.
*   `SKPhysicsBody` for collision detection.
*   `SKEmitterNode` for particle effects (thruster).
*   Managing child nodes (thruster emitter).
*   Interaction with the scene (shooting, game over).

#### `EnemyNode.swift`
Represents enemy spaceships.

*   **Conforms to `Damageable`**.
*   **`static func newInstance(...)`**: Factory method.
    *   Loads "Minion 1" texture.
    *   Sets up physics body similar to `PlayerNode` but with `Constants.PhysicsCategory.enemy`. Its `contactTestBitMask` includes player projectiles and the player itself.
    *   Spawns off-screen to the right at a random Y position.
*   **`startMoving()`**:
    *   Uses `SKAction.customAction(withDuration:...)` to create complex movement.
    *   The enemy moves horizontally across the screen while also moving up and down in a sine wave pattern. The custom action closure calculates the `node.position` at each step (`elapsedTime`).
    *   An `SKAction.removeFromParent()` is sequenced to remove the enemy once it moves off-screen.
*   **`startShooting(in scene: SKScene)` & `stopShooting()` & `shoot(in scene: SKScene)`**:
    *   `startShooting()`: Uses a repeating `SKAction` sequence (`SKAction.wait` and `SKAction.run`) to make the enemy shoot periodically. The interval between shots is randomized within a range.
    *   `stopShooting()`: Removes the shooting action using its key.
    *   `shoot()`: Creates a `ProjectileNode` of type `.enemy` and launches it towards the left.
*   **`takeDamage(amount: Int, in scene: SKScene?)`**:
    *   Reduces health. Calls `animateDamage()`.
    *   If health is zero, stops movement and shooting, then calls `explode()` (which uses `ExplosionNode` and removes the enemy).

**SpriteKit Relevance:**
*   `SKSpriteNode`, `SKTexture`, `SKPhysicsBody`.
*   Advanced movement with `SKAction.customAction`.
*   Timed actions and sequences for behavior patterns (shooting).
*   Managing actions by key (`removeAction(forKey:)`).

#### `AsteroidNode.swift`
Represents space asteroids.

*   **Conforms to `Damageable`**.
*   **`static func newInstance(...)`**: Factory method.
    *   Loads "Asteroid" texture.
    *   Generates a random size for the asteroid within a given range.
    *   Physics body is a circle: `SKPhysicsBody(circleOfRadius:)`. Category is `Constants.PhysicsCategory.asteroid`.
    *   Spawns off-screen to the right.
*   **`startMoving()`**:
    *   A `SKAction.rotate(byAngle:duration:)` combined with `SKAction.repeatForever` makes the asteroid spin.
    *   `SKAction.moveBy(x:y:duration:)` moves it horizontally across the screen.
    *   Sequenced `SKAction.removeFromParent()` for cleanup.
*   **`takeDamage(amount: Int, in scene: SKScene?)`**:
    *   Reduces health. Calls `animateDamage()`.
    *   If health is zero, stops movement and calls `explode()`.

**SpriteKit Relevance:**
*   `SKSpriteNode`, `SKTexture`.
*   Circular `SKPhysicsBody`.
*   Combining `SKAction`s for movement and rotation.

#### `ProjectileNode.swift`
Represents projectiles fired by the player and enemies.

*   **`SKNode` Subclass**: This is not an `SKSpriteNode` directly. It acts as a container for its visual representation, which is an `SKEmitterNode`.
*   **`ProjectileType` Enum**: Differentiates between `.player` and `.enemy` projectiles.
*   **`static func newInstance(...)`**: Factory method.
    *   Determines emitter file ("Laser 1.sks" or "EnemyProjectile.sks") based on `type`.
    *   Creates an `SKEmitterNode` from the .sks file and C. If the SKS file defines particles shooting "up" (positive Y axis) and the projectile needs to move horizontally, `emitterNode.zRotation` is adjusted (e.g., `CGFloat.pi` for enemy projectiles to shoot left if their SKS emits right).
    *   If the emitter fails to load, a fallback `SKSpriteNode` (a colored rectangle) is used as a visual.
    *   **Physics Body**: `SKPhysicsBody(rectangleOf: initialVisualSize)`. This is important: the physics body is a simple rectangle, not based on the potentially complex particle shape.
        *   Category is `Constants.PhysicsCategory.projectile`.
        *   `contactTestBitMask` is set based on projectile type (player projectiles test against enemies/asteroids; enemy projectiles test against the player).
*   **`launch(from startPoint: CGPoint, initialVelocity: CGVector, scene: SKScene)`**:
    *   Positions the projectile and adds it to the `scene`.
    *   `self.physicsBody?.isDynamic = true`.
    *   `self.physicsBody?.velocity = initialVelocity`: The primary way this projectile moves is by setting an initial velocity. SpriteKit's physics engine then handles its trajectory.
    *   An `SKAction` sequence is run to automatically remove the projectile after a certain lifetime (`detonate(offScreen: true)`) if it doesn't hit anything.
*   **`detonate(offScreen: Bool)`**:
    *   `self.physicsBody = nil`: Disables further physics interactions.
    *   Stops all actions.
    *   Stops new particle emission (`emitter?.particleBirthRate = 0`) and lets existing particles fade out.
    *   If not `offScreen` (i.e., it hit something or its lifetime expired mid-screen), it shows an impact explosion using another `SKEmitterNode` ("ProjectileExplode.sks").
    *   Removes itself from the parent node after a short delay.

**SpriteKit Relevance:**
*   Using `SKNode` as a container.
*   `SKEmitterNode` as the primary visual for projectiles.
*   Particle file loading and configuration (`.sks` files).
*   Physics-based movement using `velocity`.
*   Using `SKAction` for lifetime management.
*   Dynamically creating and removing nodes.

#### `ExplosionNode.swift`
This is a utility class, not an `SKNode` subclass itself. It provides a static method to create and display explosion particle effects.

*   **`static func showExplosion(at position: CGPoint, in scene: SKScene)`**:
    *   Loads an `SKEmitterNode` from "Explosion.sks".
    *   Sets its `position` and `zPosition`.
    *   Adds the emitter to the provided `scene`.
    *   Calculates an `estimatedExplosionDuration` based on particle lifetime properties.
    *   Runs an `SKAction.sequence` on the emitter: `wait` for the duration, then `removeFromParent()`. This ensures the particle effect plays out completely before the emitter node is removed from the scene.

**SpriteKit Relevance:**
*   Centralized way to trigger a common particle effect (`SKEmitterNode`).
*   Managing the lifecycle of temporary effect nodes using `SKAction`.

### 5. Game Mechanics & Protocols

#### `Damageable.swift`
This protocol defines a common interface for game entities that can take damage and be destroyed.

*   **Protocol Definition**:
    *   `health: Int { get set }`: A property to store the entity's health.
    *   `takeDamage(amount: Int, in scene: SKScene?)`: Method to apply damage.
    *   `animateDamage(tintRed: Bool, shakeIntensity: CGFloat)`: Method for visual damage feedback.
    *   `explode(in scene: SKScene?)`: Method to handle the entity's destruction.
*   **Extension `where Self: SKNode`**: Provides default implementations for `SKNode` conforming types.
    *   **`animateDamage(...)`**:
        *   Creates a shake animation using a sequence of `SKAction.moveBy` actions.
        *   Optionally creates a red tint flash animation using `SKAction.colorize(with:colorBlendFactor:duration:)`.
        *   Runs these actions concurrently using `SKAction.group()`.
    *   **`explode(in scene: SKScene?)`**:
        *   Calls `ExplosionNode.showExplosion()` at the node's current position.
        *   Removes the node from its parent (`self.removeFromParent()`).

**SpriteKit Relevance:**
*   Illustrates protocol-oriented programming in a SpriteKit context.
*   `SKAction`s are heavily used in the default `animateDamage` implementation for visual effects (movement, color changes).
*   Demonstrates how common behaviors (like exploding) can be centralized.

### 6. Utilities

#### `Constants.swift`
A struct holding globally accessible constants.

*   **`PhysicsCategory`**: Defines `UInt32` bitmasks for different types of physics bodies. These are crucial for `categoryBitMask`, `collisionBitMask`, and `contactTestBitMask` to control how physics bodies interact.
*   **`ZPositions`**: Defines `CGFloat` values for the `zPosition` property of nodes, controlling their rendering order (draw order).
*   **Game Parameters**: Speeds for player, projectiles, enemies, asteroids. Cooldowns for shooting. Initial health values. Spawn intervals. Parameters for enemy sine wave movement. Background scroll speed.
*   **HUD Constants**: Dimensions and spacing for HUD elements like health hearts.

**SpriteKit Relevance:** Centralizing these values makes tweaking game balance and appearance easier. `PhysicsCategory` and `ZPositions` are fundamental to SpriteKit's physics and rendering systems.

#### `SKNodeExtensions.swift`
This file is currently empty but is a placeholder for any custom extensions that might be added to `SKNode` or its subclasses to provide shared utility functions.

#### `NSImage` Extension (within `GameScene.swift`)
*   **`tinted(with color: NSColor) -> NSImage`**:
    *   This extension method allows an `NSImage` to be tinted with a specific color.
    *   It works by creating a copy of the image, locking focus on it, setting the fill color, and then drawing the image with the `.sourceAtop` compositing operation. This operation draws the source image only where it overlaps the existing (now color-filled) content, effectively tinting it.
    *   This is particularly useful for SF Symbols when `isTemplate` is true, as they are designed to be styled this way.

**SpriteKit Relevance:** While not a direct SpriteKit API, it's a common helper when preparing `SKTexture`s from `NSImage`s, especially for UI elements that need dynamic coloring. The resulting tinted `NSImage` is then converted to an `SKTexture`.

### 7. SpriteKit Key Concepts Summary

This project effectively utilizes many core SpriteKit features:

*   **`SKView`**: The macOS view that hosts and renders SpriteKit content.
*   **`SKScene`**: Manages a self-contained part of the game (menu, gameplay, game over). It's the root of the node tree for that part and often contains game logic and event handling.
*   **`SKNode`**: The basic building block. Everything in a scene is an `SKNode` or a subclass. Nodes can have children, forming a hierarchy. `PlayerNode`, `EnemyNode`, `ProjectileNode` (which contains an emitter) are examples.
*   **`SKSpriteNode`**: A specialized node for drawing images (textures) or solid colors. Used for player, enemies, asteroids, backgrounds, and UI hearts.
*   **`SKLabelNode`**: A node for displaying text. Used for titles, scores, and instructions.
*   **`SKEmitterNode`**: A node that renders particle systems defined in `.sks` files (created with Xcode's Particle Editor). Used for explosions, thrusters, and projectile visuals.
*   **`SKTexture`**: Represents image data that can be applied to `SKSpriteNode`s.
*   **`SKAction`**: The workhorse for animations and timed behaviors. Used for movement, rotation, scaling, fading, color changes, running custom code blocks, sequencing actions, grouping actions, and repeating actions.
*   **`SKPhysicsBody`**: Adds physics properties to a node, enabling it to participate in the physics simulation (movement, collision detection).
    *   **`categoryBitMask`**: Identifies the type of a physics body.
    *   **`collisionBitMask`**: Determines which categories of physics bodies this body will physically collide with (bounce off).
    *   **`contactTestBitMask`**: Determines which categories will generate a contact notification when they touch this body (without necessarily causing a physical collision response if not also in `collisionBitMask`).
*   **`SKPhysicsContactDelegate`**: A protocol implemented by `GameScene` to receive notifications when physics bodies make contact.
*   **Coordinate System**: SpriteKit's coordinate system typically has `(0,0)` at the bottom-left (if `anchorPoint` is default) or can be changed (e.g., `(0.5, 0.5)` for center origin).
*   **`zPosition`**: A `CGFloat` property of `SKNode` that controls the front-to-back drawing order. Nodes with higher `zPosition`s are drawn on top of nodes with lower `zPosition`s.
*   **Scene Transitions (`SKTransition`)**: Provides animated transitions when switching between `SKScene`s (e.g., fade, doors open/close).
