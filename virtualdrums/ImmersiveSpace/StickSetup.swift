import RealityKit
import SwiftUI

/// Handles creation and configuration of drum sticks.
@MainActor
final class StickSetup {

    private unowned let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func setupDrumSticks(content: RealityViewContent) -> (left: StickState, right: StickState) {
        let left = setupStick(chirality: .left, content: content)
        let right = setupStick(chirality: .right, content: content)
        return (left, right)
    }

    func updateStickLength(_ stick: inout StickState?, chirality: AnchoringComponent.Target.Chirality) {
        guard var s = stick else { return }

        s.stickEntity.children.removeAll()
        let tip = makeStickTip(chirality: chirality)
        let handle = makeStickHandle()
        s.stickEntity.addChild(tip)
        s.stickEntity.addChild(handle)

        // Promote updated collision shapes to the stick root
        if let tipCollision = tip.components[CollisionComponent.self] {
            s.stickEntity.components.set(CollisionComponent(shapes: tipCollision.shapes, filter: tipCollision.filter))
        }

        s.tipEntity = tip
        stick = s
    }
}

// MARK: - Scene initialization

@MainActor
extension StickSetup {

    /// Creates a single stick and anchors it to the given hand.
    private func setupStick(chirality: AnchoringComponent.Target.Chirality, content: RealityViewContent) -> StickState {
        let tip = makeStickTip(chirality: chirality)
        let handle = makeStickHandle()
        let stick = Entity()
        stick.addChild(tip)
        stick.addChild(handle)

        // Needed for Collision Detection and Raycasting.
        // This also propagates to child entities that contain meshes.
        stick.components.set(InputTargetComponent())

        // Promote the tip’s collision configuration to the root stick entity
        stick.components.set(
            CollisionComponent(
                shapes: tip.collision!.shapes,
                filter: tip.collision!.filter
            )
        )

        let anchor: AnchorEntity = positionStickInHand(stick: stick, chirality: chirality)
        content.add(anchor)

        return StickState(stickEntity: stick, tipEntity: tip)
    }

    private func makeStickHandle() -> ModelEntity {
        let mesh = MeshResource.generateCylinder(
            height: appState.stickHandleLength,
            radius: Config.stickHandleRadius
        )
        let material = SimpleMaterial(color: .brown, isMetallic: false)
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.position.y = appState.stickHandleLength / 2.0
        return model
    }

    private func makeStickTip(chirality: AnchoringComponent.Target.Chirality) -> ModelEntity{
        let mesh = MeshResource.generateSphere(radius: Config.stickTipRadius)
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.position.y = appState.stickHandleLength
        model.scale.y = 1.2

        model.components.set(
            CollisionComponent(
                shapes: [.generateSphere(radius: Config.stickTipRadius)],
                // Only collides with entities in the "drum" collision group
                filter: .init(
                    group: chirality == .left ? .stickTipLeft : .stickTipRight,
                    mask: .drum
                )
            )
        )

        return model
    }

    /// Positions and orients the stick to match a realistic hand grip, then anchors it to the user’s palm.
    private func positionStickInHand(stick: Entity, chirality: AnchoringComponent.Target.Chirality) -> AnchorEntity {
        stick.position = [0, 0.025, -0.015]  // Offset to approximate how a real drum stick is held
        let rotationX = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
        let rotationZSign: Float = (chirality == .left) ? -1 : 1  // Mirror for left hand
        let rotationZ = simd_quatf(angle: rotationZSign * .pi / 2.2, axis: [0, 0, 1])
        stick.orientation = rotationX * rotationZ

        let anchor = AnchorEntity(
            .hand(chirality, location: .palm),
            trackingMode: .continuous,
            // !
            // Hand anchors use a separate physics simulation by default.
            // Disabling it ensures collisions are detected with entities anchored elsewhere (e.g., the drums).
            physicsSimulation: .none
        )

        anchor.addChild(stick)
        return anchor
    }
}
