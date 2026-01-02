import SwiftUI
import RealityKit

#if targetEnvironment(simulator)
enum SimulatorStickConfig {
    static let radius: Float = 0.01
    static let restPosition: SIMD3<Float> = [0, 0.35, -0.35]
    static let sweepDistance: Float = 0.3
    static let sweepDurationSeconds: Double = 1.0
    static let moveStep: Float = 0.02
}

extension ImmersiveView {
    
    @MainActor
    func setupSimulatorStick(content: RealityViewContent) async {
        guard simulatorStickState == nil else { return }

        let stickEntity = makeSimulatorStick()
        let anchor = AnchorEntity(world: .zero)
        simulatorStickPosition = SimulatorStickConfig.restPosition
        stickEntity.position = simulatorStickPosition
        anchor.addChild(stickEntity)
        content.add(anchor)

        simulatorStickState = StickState(stickEntity: stickEntity, tipEntity: stickEntity)
    }

    func makeSimulatorStick() -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: SimulatorStickConfig.radius)
        let material = SimpleMaterial(color: .green, isMetallic: false)
        let stickEntity = ModelEntity(mesh: mesh, materials: [material])
        stickEntity.name = "sim_stick"

        stickEntity.components.set(InputTargetComponent())
        stickEntity.components.set(
            CollisionComponent(
                shapes: [.generateSphere(radius: SimulatorStickConfig.radius)],
                filter: .init(group: .stickTipLeft, mask: .drum)
            )
        )
        stickEntity.components.set(
            PhysicsBodyComponent(massProperties: .default, material: .default, mode: .kinematic)
        )

        return stickEntity
    }

    func startSimulatorSweep(at worldPosition: SIMD3<Float>) {
        simulatorSweepTask?.cancel()

        simulatorSweepTask = Task { @MainActor in
            guard var simStickState = simulatorStickState else { return }

            simStickState.lastTipPosition =
                simStickState.tipEntity.position(relativeTo: nil)
            simulatorStickState = simStickState
            
            simulatorStickPosition = worldPosition
            simStickState.stickEntity.setPosition(simulatorStickPosition, relativeTo: nil)

            await runSimulatorSweep(from: worldPosition, stick: simStickState.stickEntity)
        }
    }

    func runSimulatorSweep(from start: SIMD3<Float>, stick: Entity) async {
        let distance = SimulatorStickConfig.sweepDistance
        let duration = SimulatorStickConfig.sweepDurationSeconds
        let offsets: [SIMD3<Float>] = [
            [distance, 0, 0],
            [-distance, 0, 0],
            [0, distance, 0],
            [0, -distance, 0],
            [0, 0, distance],
            [0, 0, -distance]
        ]

        var current = start
        for offset in offsets {
            if Task.isCancelled { break }
            let target = current + offset
            await moveSimulatorStick(stick, to: target, duration: duration)
            current = target
        }
    }

    func moveSimulatorStick(_ stick: Entity, to target: SIMD3<Float>, duration: Double) async {
        stick.move(
            to: Transform(translation: target),
            relativeTo: nil,
            duration: duration,
            timingFunction: .easeInOut
        )

        let sleepNanos = UInt64(duration * 1_000_000_000)
        try? await Task.sleep(nanoseconds: sleepNanos)

        simulatorStickPosition = target
        stick.setPosition(simulatorStickPosition, relativeTo: nil)
    }

    func moveSimulatorStick(dx: Float, dy: Float, dz: Float) {
        guard var simStickState = simulatorStickState else { return }

        simStickState.lastTipPosition =
            simStickState.tipEntity.position(relativeTo: nil)
        simulatorStickState = simStickState
                
        simulatorStickPosition += [dx, dy, dz]
        simStickState.stickEntity.setPosition(simulatorStickPosition, relativeTo: nil)
    }

    func resetSimulatorStick() {
        guard var simStickState = simulatorStickState else { return }

        simStickState.lastTipPosition =
            simStickState.tipEntity.position(relativeTo: nil)
        simulatorStickState = simStickState

        simulatorStickPosition = SimulatorStickConfig.restPosition
        simStickState.stickEntity.setPosition(simulatorStickPosition, relativeTo: nil)
    }

    func resolveTapWorldPosition(entity: Entity, location: SIMD3<Float>) -> SIMD3<Float> {
        let fallback = entity.position(relativeTo: nil)
        guard location.x.isFinite, location.y.isFinite, location.z.isFinite else {
            return fallback
        }

        let entityWorld = fallback
        let worldFromLocal = entity.convert(position: location, to: nil)
        let distFromLocal = simd_length(worldFromLocal - entityWorld)
        let distAsIs = simd_length(location - entityWorld)

        if distFromLocal.isFinite, distAsIs.isFinite {
            return distFromLocal <= distAsIs ? worldFromLocal : location
        }
        if distFromLocal.isFinite {
            return worldFromLocal
        }
        if distAsIs.isFinite {
            return location
        }
        return fallback
    }
}
#endif // targetEnvironment(simulator)
