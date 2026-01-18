import RealityKit
import SwiftUI

/// Handles loading and configuring the drum set entities in the scene.
@MainActor
final class DrumSetup {

    // Scene root for drum entities
    private(set) var drumRootEntity = Entity()

    // Hi-hat
    private(set) var hiHatTopEntity: ModelEntity?
    private var hiHatTopParentRestPosition: SIMD3<Float> = .zero

    // Kick drum
    private(set) var kickDrumEntity: ModelEntity?
    private(set) var kickBeater: ModelEntity?
    private var kickBeaterRestPosition: SIMD3<Float> = .zero

    // Drum rest rotations
    private var drumRestOrientations: [Entity.ID: simd_quatf] = [:]

    // Dependencies
    private unowned let appState: AppState
    private let drumController: DrumController
    private let footPedalManager: FootPedalManager

    init(
        appState: AppState,
        drumController: DrumController = .shared,
        footPedalManager: FootPedalManager = .shared
    ) {
        self.appState = appState
        self.drumController = drumController
        self.footPedalManager = footPedalManager
    }

    func restOrientation(for entity: Entity) -> simd_quatf? {
        drumRestOrientations[entity.id]
    }

    func replaceDrumSet(with drumSet: DrumSetID) async {
        // Remove all existing drums from root (simple & robust)
        drumRootEntity.children.removeAll()

        do {
            let drumSetEntity = try await Entity(named: drumSet.rawValue, in: .main)
            drumSetEntity.position = Config.initialDrumSetPosition
            drumRootEntity.addChild(drumSetEntity)

            await setupTargetsRecursively(for: drumSetEntity)
        } catch {
            print("❌ Failed to load drum set model:", error)
        }
    }

    /// Moves the kick beater towards/away from the drum face.
    /// The beater is not animated – therefore we can set the position directly.
    func moveKickBeaterEntity(distance: Float) {
        guard let beater = kickBeater else { return }
        let beaterWidth = beater.visualBounds(relativeTo: beater.parent).extents.x
        let maxOffSet = beaterWidth * 2.0
        let offset = SIMD3<Float>(0, -(distance * maxOffSet), 0) // towards the user, away from the drum face
        kickBeater?.position = kickBeaterRestPosition + offset
    }

    /// Opens and closes the hi-hat by translating its parent instead of the cymbal itself.
    ///
    /// The cymbal uses `move()` for the hit “wiggle” animation. Changing its transform
    /// directly for pedal movement would interrupt that animation and leave it tilted.
    /// Moving the parent lets the pedal motion and hit animation coexist safely.
    func moveHiHatTopEntity(distance: Float) {
        guard
            let hiHat = hiHatTopEntity,
            let parent = hiHat.parent
        else { return }

        let bounds = hiHat.visualBounds(relativeTo: nil)
        let radius = max(bounds.extents.x, bounds.extents.z) * 0.5
        let maxOffset = radius * 0.25

        let offset = SIMD3<Float>(0, 0, distance * maxOffset) // upwards, away from hi-hat bottom
        parent.position = hiHatTopParentRestPosition + offset
    }
}

// MARK: - Scene initialization

@MainActor
extension DrumSetup {

    private func setupTargetsRecursively(for entity: Entity) async {
        for child in entity.children {
            if let model = child as? ModelEntity {  // must be a ModelEntity (→ has a mesh)

                if appState.handedness == .left {
                    entity.applyLeftHandednessMirror()
                }

                if let drumID = DrumID(rawValue: model.name) {  // must be a recognized drum (→ named "target_[drum_piece]")
                    await setupDrumTarget(entity: model, drumID: drumID)
                }

                switch model.name {
                case DrumID.target_hi_hat_top.rawValue: setupHiHatTop(entity: model)
                case DrumID.target_kick.rawValue: setupKickDrum(entity: model)
                case "kick_beater": setupKickBeater(entity: model)
                case "hi_hat_bottom": await setupHiHatBottom(entity: model)
                default: break
                }
            }
            await setupTargetsRecursively(for: child)  // recurse into grandchildren, etc.
        }
    }

    private func setupDrumTarget(entity: ModelEntity, drumID: DrumID) async {
        do {
            let shape = try await ShapeResource.generateConvex(from: entity.model!.mesh)
            entity.components.set(
                CollisionComponent(
                    shapes: [shape],
                    filter: .init(
                        group: .drum,
                        mask: .stickTipLeft.union(.stickTipRight)
                    )
                )
            )
        } catch {
            print("⚠️ Could not generate collider for:", entity.name, error)
        }

        drumRestOrientations[entity.id] = entity.orientation

        #if targetEnvironment(simulator)
            entity.components.set(InputTargetComponent())
        #endif

        // Load sound etc.
        drumController.onDrumLoaded(drumID)
    }

    private func setupKickDrum(entity: ModelEntity) {
        kickDrumEntity = entity
    }

    private func setupKickBeater(entity: ModelEntity) {
        kickBeater = entity
        kickBeaterRestPosition = entity.position

        kickBeater?.isEnabled = footPedalManager.isControllerConnected
        moveKickBeaterEntity(distance: footPedalManager.kick.distance)
    }

    private func setupHiHatTop(entity: ModelEntity) {
        hiHatTopEntity = entity
        hiHatTopParentRestPosition = entity.parent!.position

        entity.components.set(InputTargetComponent())

        moveHiHatTopEntity(distance: appState.isHiHatClosed ? 0.0 : 1.0)
    }

    private func setupHiHatBottom(entity: ModelEntity) async {
        do {
            let shape = try await ShapeResource.generateConvex(from: entity.model!.mesh)
            entity.components.set(
                CollisionComponent(
                    shapes: [shape],
                    filter: .init(
                        group: [],
                        mask: []
                    )
                )
            )
        } catch {
            print("⚠️ Could not generate collider for:", entity.name, error)
        }

        entity.components.set(InputTargetComponent())
    }
}
