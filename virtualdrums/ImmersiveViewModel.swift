//
//  ImmersiveViewModel.swift
//  virtualdrums
//
//  Created by Oliver Kühle on 12.01.26.
//

import ARKit
import Combine
import RealityKit
import SwiftUI

extension CollisionGroup {
    static let drum = CollisionGroup(rawValue: 1 << 0)
    static let stickTipLeft = CollisionGroup(rawValue: 1 << 1)
    static let stickTipRight = CollisionGroup(rawValue: 1 << 2)
}

struct StickState {
    let stickEntity: Entity
    let tipEntity: Entity
    var lastTipPosition: SIMD3<Float>?
    var isInsideDrum: Bool = false  // Prevents multiple hits while inside the drum
}

struct StickConfig {
    static let handleLength: Float = 0.25
    static let handleRadius: Float = 0.004
    static let tipRadius: Float = 0.005
}

@MainActor
final class ImmersiveViewModel: ObservableObject {

    // External systems
    private(set) var appState: AppState!
    let drumController = DrumController.shared
    let footPedalManager = FootPedalManager.shared
    let handGripManager = HandGripManager.shared

    // Scene root for drum entities
    private let drumRootEntity = Entity()

    // Hi-hat
    private var hiHatTopEntity: ModelEntity?
    private var hiHatTopParentRestPosition: SIMD3<Float> = .zero  // refactor to ModelEntity extension

    // Kick
    private var bassDrumEntity: ModelEntity?  // store to save lookup
    private var bassBeater: ModelEntity?
    private var bassBeaterRestPosition: SIMD3<Float> = .zero  // refactor to ModelEntity extension

    // Drum rest rotations
    private var drumRestOrientations: [Entity.ID: simd_quatf] = [:]  // refactor to ModelEntity extension

    // Sticks
    private var leftStick: StickState?
    private var rightStick: StickState?

    // Hand tracking
    private let handTrackingSession = ARKitSession()
    private let handProvider = HandTrackingProvider()

    // Subscriptions and Tasks
    private var sceneUpdates: EventSubscription?
    private var handUpdates: Task<Void, Never>?

    // Simulator
    #if targetEnvironment(simulator)
        var simulatorStickState: StickState?
        var simulatorStickPosition: SIMD3<Float> = SimulatorStickConfig.restPosition
        var simulatorSweepTask: Task<Void, Never>?
    #endif  // targetEnvironment(simulator)

    deinit {
        handUpdates?.cancel()
        sceneUpdates?.cancel()
    }

    // MARK: - Public API called by the View

    func setup(content: RealityViewContent, appState: AppState) async {
        self.appState = appState

        content.add(drumRootEntity)

        await replaceDrumSet(with: appState.selectedDrumSet)

        #if targetEnvironment(simulator)
            await setupSimulatorStick(content: content)
        #endif

        #if !targetEnvironment(simulator)
            await setupDrumSticks(content: content)
            await setupHandTracking()
        #endif

        setupUpdateLoop(content: content)
    }

    func onChangeControllerConnected(_ isConnected: Bool) {
        bassBeater?.isEnabled = isConnected
    }

    func onChangeDrumSet(to drumSet: DrumSetID) {
        Task { await replaceDrumSet(with: drumSet) }
    }

    func onChangeHiHatTopPosition(to distance: Float) {
        moveHiHatTopEntity(distance: distance)

        let wasClosed = appState.isHiHatClosed
        let isClosed = distance == 0.0

        // Trigger onHiHatClosed when pedal is pressed down
        if !wasClosed && isClosed {
            let hitWorldPosition = hiHatTopEntity!.position(relativeTo: nil)
            onDrumHit(
                drumID: .target_hi_hat_chick,
                drumEntity: hiHatTopEntity!,
                hitWorldPosition: hitWorldPosition
            )
        }

        // Publish only if state changed
        if appState.isHiHatClosed != isClosed {
            appState.isHiHatClosed = isClosed
        }
    }

    func onChangeBassDrumBeaterPosition(from previousDistance: Float, to distance: Float) {
        moveBassBeaterEntity(distance: distance)

        if distance == 0.0 && previousDistance != 0.0 {
            let hitWorldPosition = bassBeater!.position(relativeTo: nil)
            onDrumHit(
                drumID: .target_bass_drum,
                drumEntity: bassDrumEntity!,
                hitWorldPosition: hitWorldPosition
            )
        }
    }
    
    func onTapGesture(value: EntityTargetValue<SpatialTapGesture.Value>) {
        let entity = value.entity
        let location3D = value.location3D

        guard let drumID = DrumID(rawValue: entity.name) else { return }

        if drumID == .target_hi_hat_top {
            // Toggle open/closed
            let distance: Float = appState.isHiHatClosed ? 1.0 : 0.0
            onChangeHiHatTopPosition(to: distance)
        }

        #if targetEnvironment(simulator)
            let localPosition = SIMD3<Float>(Float(location3D.x), Float(location3D.y), Float(location3D.z))
            // TODO: calculate correct world position
            let worldPosition = resolveTapWorldPosition(entity: entity, location: localPosition)
            startSimulatorSweep(at: worldPosition)
            
            onDrumHit(
                drumID: drumID,
                drumEntity: value.entity,
                hitWorldPosition: worldPosition,
            )
        #endif  // targetEnvironment(simulator)
    }

}

// MARK: - Private event handlers

@MainActor
extension ImmersiveViewModel {
    
    private func moveBassBeaterEntity(distance: Float) {
        bassBeater?.position = bassBeaterRestPosition + SIMD3<Float>(0, -1 * distance * 10, 0)
    }

    /// Opens and closes the hi-hat by translating its parent instead of the cymbal itself.
    ///
    /// The cymbal uses `move()` for the hit “wiggle” animation. Changing its transform
    /// directly for pedal movement would interrupt that animation and leave it tilted.
    /// Moving the parent lets the pedal motion and hit animation coexist safely.
    private func moveHiHatTopEntity(distance: Float) {
        guard
            let hiHat = hiHatTopEntity,
            let parent = hiHat.parent
        else { return }
        
        // TODO: Models have multiple diffrent parent scales, which first need to be removed, before using the radius for maxLift
        // // Use the cymbal's actual size so lift scales correctly across drum kits
        // let bounds = hiHat.visualBounds(relativeTo: parent)
        // let radius = max(bounds.extents.x, bounds.extents.y) * 0.5
        // let maxLift = radius * 0.5
        let maxLift: Float = appState.selectedDrumSet == .burgundy_drum ? 8 : 4

        
        parent.position = hiHatTopParentRestPosition + SIMD3<Float>(0, 0, distance * maxLift)
    }
    
    private func onDrumHit(drumID: DrumID, drumEntity: Entity, hitWorldPosition: SIMD3<Float>, velocity: Float? = nil) {
        var resolvedDrumID = drumID
        if drumID == .target_hi_hat_top {
            resolvedDrumID = appState.isHiHatClosed
                ? .target_hi_hat_closed
                : .target_hi_hat_open
        }

        animateHit(entity: drumEntity, hitWorldPosition: hitWorldPosition, velocity: velocity)
        drumController.onHit(drum: resolvedDrumID, velocity: velocity)
    }

    private func animateHit(entity: Entity, hitWorldPosition: SIMD3<Float>, velocity: Float? = nil) {
        guard let restOrientation = drumRestOrientations[entity.id] else {
            return
        }

        let center = entity.position(relativeTo: nil)
        let rawHitDir = hitWorldPosition - center

        // Get the entity UP vector (direction of the drum surface)
        let transform = entity.transformMatrix(relativeTo: nil)
        let drumNormal = normalize(
            SIMD3<Float>(
                transform.columns.2.x,
                transform.columns.2.y,
                transform.columns.2.z
            )
        )

        // Hit direction → tilt axis
        let hitDirInPlane = rawHitDir - dot(rawHitDir, drumNormal) * drumNormal
        guard simd_length_squared(hitDirInPlane) > 0.0001 else { return }
        let hitDir = normalize(hitDirInPlane)
        let worldTiltAxis = normalize(cross(drumNormal, hitDir))
        let localTiltAxis = normalize(entity.convert(direction: worldTiltAxis, from: nil))

        // Hit radius (distance from center)
        let hitRadius = simd_length(hitDirInPlane)

        // Tuned drum radius (world units)

        let bounds = entity.visualBounds(relativeTo: nil)
        let radius = max(bounds.extents.x, bounds.extents.z) * 0.5

        // Radius factor (0.0 - 1.0), influences tilt angle
        let radiusFactor = min(hitRadius / radius, 1.0)

        // strikeSpeed → angle
        let rawSpeed = velocity ?? 3.0
        let clampedSpeed: Float = min(max(rawSpeed, 0.2), 6.0)

        // Hi-hat pedal dampening
        var hiHatFactor: Float? = nil
        if entity.name == DrumID.target_hi_hat_top.rawValue {
            hiHatFactor = appState.isHiHatClosed
                ? 0.03
                : max(0.03, footPedalManager.hiHat.distance)  // TODO:
        }

        let angle = clampedSpeed * 0.05 * radiusFactor * (hiHatFactor ?? 1.0)

        let tilt = simd_quatf(angle: angle, axis: localTiltAxis)

        entity.move(
            to: Transform(rotation: tilt * restOrientation),
            relativeTo: entity.parent,
            duration: 0.05,
            timingFunction: .easeOut
        )

        entity.move(
            to: Transform(rotation: restOrientation),
            relativeTo: entity.parent,
            duration: 0.3,
            timingFunction: .easeInOut
        )
    }

}

// MARK: - Scene setup (drums)

@MainActor
extension ImmersiveViewModel {

    private func replaceDrumSet(with drumSet: DrumSetID) async {
        // Remove all existing drums from root (simple & robust)
        drumRootEntity.children.removeAll()

        do {
            let drumSetEntity = try await Entity(named: drumSet.rawValue, in: .main)
            drumSetEntity.position = [0, 0.15, -0.6]
            drumRootEntity.addChild(drumSetEntity)

            await setupTargetsRecursively(for: drumSetEntity)
        } catch {
            print("❌ Failed to load drum set model:", error)
        }
    }

    private func setupTargetsRecursively(for entity: Entity) async {
        for child in entity.children {
            if let model = child as? ModelEntity {  // must be a ModelEntity (→ has a mesh)

                if let drumID = DrumID(rawValue: model.name) {  // must be a recognized drum (→ named "target_[drum_piece]")
                    await setupDrumTarget(entity: model, drumID: drumID)
                }

                switch model.name {
                case DrumID.target_hi_hat_top.rawValue: setupHiHatTop(entity: model)
                case DrumID.target_bass_drum.rawValue: setupBassDrum(entity: model)
                case "bass_drum_pedal": setupBassBeater(entity: model)
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

    private func setupBassDrum(entity: ModelEntity) {
        bassDrumEntity = entity
    }

    private func setupBassBeater(entity: ModelEntity) {
        bassBeater = entity
        bassBeaterRestPosition = entity.position

        bassBeater?.isEnabled = footPedalManager.isControllerConnected
        moveBassBeaterEntity(distance: footPedalManager.kick.distance)
    }
    
    private func setupHiHatTop(entity: ModelEntity) {
        hiHatTopEntity = entity
        hiHatTopParentRestPosition = entity.parent!.position

        entity.components.set(InputTargetComponent())

        moveHiHatTopEntity(distance: appState.isHiHatClosed ? 0.0 : 1.0)
    }
}

// MARK: - Scene setup (sticks)

@MainActor
extension ImmersiveViewModel {

    private func setupDrumSticks(content: RealityViewContent) async {
        self.leftStick = setupStick(chirality: .left, content: content)
        self.rightStick = setupStick(chirality: .right, content: content)
    }

    /// Creates a single stick and anchors it to the given hand.
    private func setupStick(chirality: AnchoringComponent.Target.Chirality, content: RealityViewContent) -> StickState {
        let tip = makeStickTip(chirality: chirality)
        let handle = makeStickHandle(chirality: chirality)
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

    private func makeStickHandle(chirality: AnchoringComponent.Target.Chirality) -> ModelEntity {
        let mesh = MeshResource.generateCylinder(
            height: StickConfig.handleLength,
            radius: StickConfig.handleRadius
        )
        let material = SimpleMaterial(color: .brown, isMetallic: false)
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.position.y = StickConfig.handleLength / 2
        return model
    }

    private func makeStickTip(chirality: AnchoringComponent.Target.Chirality) -> ModelEntity{
        let mesh = MeshResource.generateSphere(radius: StickConfig.tipRadius)
        let material = SimpleMaterial(color: .white, isMetallic: false)
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.position.y = StickConfig.handleLength
        model.scale.y = 1.2

        model.components.set(
            CollisionComponent(
                shapes: [.generateSphere(radius: StickConfig.tipRadius)],
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

// MARK: - Hand tracking + Update loops

@MainActor
extension ImmersiveViewModel {

    private func setupHandTracking() async {
        try? await handTrackingSession.run([handProvider])

        handUpdates = Task {
            for await update in handProvider.anchorUpdates {
                handGripManager.update(for: update.anchor)
            }
        }
    }

    private func setupUpdateLoop(content: RealityViewContent) {
        self.sceneUpdates = content.subscribe(to: SceneEvents.Update.self) {
            [weak self] event in
            self?.update(deltaTime: Float(event.deltaTime))
        }
    }

    private func update(deltaTime: Float) {
        updateStickVisibility()

        #if targetEnvironment(simulator)
            processStrike(stick: &simulatorStickState, deltaTime: deltaTime)
        #else
            processStrike(stick: &leftStick, deltaTime: deltaTime)
            processStrike(stick: &rightStick, deltaTime: deltaTime)
        #endif
    }

    /// Shows or hides the drum sticks based on whether the user is gripping, matching real-world playing intent and reducing accidental interaction.
    /// Stick visibility is also tied to grip state because collision and raycast detection are strangely only reliable when the hand is in a fist.
    private func updateStickVisibility() {
        leftStick?.stickEntity.isEnabled = handGripManager.isLeftHandGripping
        rightStick?.stickEntity.isEnabled = handGripManager.isRightHandGripping
    }

    private func processStrike(stick: inout StickState?, deltaTime: Float) {
        guard var s = stick else { return }
        guard s.stickEntity.isEnabled else { return }  // only process if stick is visible (hand is gripping)

        let tipPosition = s.tipEntity.position(relativeTo: nil)
        guard let lastPosition = s.lastTipPosition else {
            // no lastPosition = first update loop → set current position as last and return
            s.lastTipPosition = tipPosition
            stick = s
            return
        }

        let strikeVelocity: SIMD3<Float> = (tipPosition - lastPosition) / deltaTime
        let strikeSpeed: Float = simd_length(strikeVelocity)
        let strikeDirection = normalize(tipPosition - lastPosition)
        let strikeDistance = distance(tipPosition, lastPosition)

        let minSpeed: Float = 0.3
        if strikeSpeed < minSpeed {
            return
        }

        guard let scene = stick?.tipEntity.scene else { return }
        let hits = scene.raycast(
            origin: lastPosition,
            direction: strikeDirection,
            length: strikeDistance,
            query: .nearest,
            mask: .drum,
        )

        processRaycastHits(s: &s, hits: hits, strikeSpeed: strikeSpeed)

        s.lastTipPosition = tipPosition
        stick = s
    }

    private func processRaycastHits(s: inout StickState, hits: [CollisionCastHit], strikeSpeed: Float) {
        if let hit = hits.first {

            #if targetEnvironment(simulator)
                updateDebugCollision(drumEntity: hit.entity, stickEntity: s.stickEntity)
            #endif

            // Get the entity UP vector (direction of the drum surface)
            let transform = hit.entity.transformMatrix(relativeTo: nil)
            let entityUp = normalize(
                SIMD3<Float>(
                    transform.columns.2.x,
                    transform.columns.2.y,
                    transform.columns.2.z
                )
            )

            // Checks if the strike was directed at the top (drum) surface (≈ within 45° of up)
            let isTopHit = dot(hit.normal, entityUp) > 0.7
            if isTopHit && !s.isInsideDrum,
                let drumId = DrumID(rawValue: hit.entity.name)
            {
                // stick hit against the up/drum side --> mark stick as inside and play sound
                s.isInsideDrum = true
                onDrumHit(
                    drumID: drumId,
                    drumEntity: hit.entity,
                    hitWorldPosition: hit.position,
                    velocity: strikeSpeed
                )

                #if targetEnvironment(simulator)
                    updateDebugHitAccepted(drumName: hit.entity.name)
                #endif
            } else {
                // stick hit a drum, but not against the up/drum side --> mark stick as inside the drum, to not trigger false hits
                s.isInsideDrum = true

                #if targetEnvironment(simulator)
                    updateDebugHitCheck(drumName: hit.entity.name, stickName: s.stickEntity.name, result: "hit rejected (not top hit or already inside)")
                #endif
            }
        } else {
            // no hits detected --> mark stick as outside the drum, to enable new hits
            s.isInsideDrum = false
        }
    }
}
