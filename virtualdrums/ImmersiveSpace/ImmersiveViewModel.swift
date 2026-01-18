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

struct StickState {
    let stickEntity: Entity
    var tipEntity: Entity
    var lastTipPosition: SIMD3<Float>?
    var isInsideDrum: Bool = false  // Prevents multiple hits while inside the drum
}

@MainActor
final class ImmersiveViewModel: ObservableObject {

    // External systems
    private(set) var appState: AppState!
    let drumController = DrumController.shared
    let footPedalManager = FootPedalManager.shared
    let handGripManager = HandGripManager.shared

    private var drumSetup: DrumSetup!
    private var stickSetup: StickSetup!

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
        var simulatorStickPosition: SIMD3<Float> = Config.simulatorRestPosition
        var simulatorSweepTask: Task<Void, Never>?
    #endif  // targetEnvironment(simulator)

    deinit {
        handUpdates?.cancel()
        sceneUpdates?.cancel()
    }

    // MARK: - Public API called by the View

    func setup(content: RealityViewContent, appState: AppState) async {
        self.appState = appState

        drumSetup = DrumSetup(appState: appState)
        stickSetup = StickSetup(appState: appState)

        content.add(drumSetup.drumRootEntity)

        await drumSetup.replaceDrumSet(with: appState.selectedDrumSet)

        #if targetEnvironment(simulator)
            await setupSimulatorStick(content: content)
        #endif

        #if !targetEnvironment(simulator)
            let sticks = stickSetup.setupDrumSticks(content: content)
            leftStick = sticks.left
            rightStick = sticks.right
            await setupHandTracking()
        #endif

        setupUpdateLoop(content: content)
    }

    func onChangeControllerConnected(_ isConnected: Bool) {
        drumSetup.kickBeater?.isEnabled = isConnected
    }

    func onChangeDrumSet() {
        Task { await drumSetup.replaceDrumSet(with: appState.selectedDrumSet) }
    }
    
    func onHandednessChanged() {
        Task { await drumSetup.replaceDrumSet(with: appState.selectedDrumSet) }
    }
    
    func onStickLengthChanged() {
        stickSetup.updateStickLength(&leftStick, chirality: .left)
        stickSetup.updateStickLength(&rightStick, chirality: .right)
    }
    
    func onDrumScaleChanged() {
        drumSetup.drumRootEntity.scale = SIMD3<Float>(repeating: appState.drumScale)
    }

    func onDrumDistanceChanged() {
        drumSetup.drumRootEntity.position.z = -(appState.drumDistance)
    }
    
    func onDrumHeightChanged() {
        drumSetup.drumRootEntity.position.y = appState.drumHeight
    }

    func onChangeHiHatTopPosition(to distance: Float) {
        drumSetup.moveHiHatTopEntity(distance: distance)

        let wasClosed = appState.isHiHatClosed
        let isClosed = distance == 0.0

        // Check for hi-hat chick hit (hi-hat was closed)
        if !wasClosed && isClosed {
            let hitWorldPosition = drumSetup.hiHatTopEntity!.position(relativeTo: nil)
            onDrumHit(
                drumID: .target_hi_hat_chick,
                drumEntity: drumSetup.hiHatTopEntity!,
                hitWorldPosition: hitWorldPosition
            )
        }

        // Publish only if state changed
        if appState.isHiHatClosed != isClosed {
            appState.isHiHatClosed = isClosed
        }
    }

    func onChangeKickBeaterPosition(from previousDistance: Float, to distance: Float) {
        drumSetup.moveKickBeaterEntity(distance: distance)

        // Check for beater hitting the drum
        if distance == 0.0 && previousDistance != 0.0 {
            let hitWorldPosition = drumSetup.kickBeater!.position(relativeTo: nil)
            onDrumHit(
                drumID: .target_kick,
                drumEntity: drumSetup.kickDrumEntity!,
                hitWorldPosition: hitWorldPosition
            )
        }
    }
    
    /// Handles tap gestures directed at any entity
    /// - Toggles hi-hat open/closed state when hi-hat is tapped
    /// - In simulator mode, starts a stick sweep and triggers a drum hit if applicable
    func onTapGesture(value: EntityTargetValue<SpatialTapGesture.Value>) {
        let entity = value.entity

        let isHiHat = (entity.name == DrumID.target_hi_hat_top.rawValue || entity.name == "hi_hat_bottom")
        if isHiHat {
            // Toggle open/closed
            let distance: Float = appState.isHiHatClosed ? 1.0 : 0.0
            onChangeHiHatTopPosition(to: distance)
        }

        #if targetEnvironment(simulator)
            let location3D = value.location3D
            let localPosition = SIMD3<Float>(Float(location3D.x), Float(location3D.y), Float(location3D.z))
            // TODO: fix: calculate correct world position
            let worldPosition = resolveTapWorldPosition(entity: entity, location: localPosition)
            startSimulatorSweep(at: worldPosition)
            
            if let target = DrumID(rawValue: entity.name) {
                onDrumHit(
                    drumID: target,
                    drumEntity: value.entity,
                    hitWorldPosition: worldPosition,
                )
            }
        #endif  // targetEnvironment(simulator)
    }

}

// MARK: - Private event handlers

@MainActor
extension ImmersiveViewModel {
    
    /// Unified drum hit handler
    /// Informs DrumController about which drum was hit and triggers visual feedback
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

    /// Applies a short tilt animation (visual hit feedback) to the drum based on:
    /// - Distance from the drum center
    /// - Strike velocity
    /// - Hi-hat pedal state (for hi-hat only)
    private func animateHit(entity: Entity, hitWorldPosition: SIMD3<Float>, velocity: Float? = nil) {
        // Retrieve the drum’s rest orientation so we can return to it after the hit.
        guard let restOrientation = drumSetup.restOrientation(for: entity) else {
            return
        }

        // World-space center position of the drum
        let center = entity.position(relativeTo: nil)

        // Vector from drum center to hit location (world space)
        let rawHitDir = hitWorldPosition - center

        // Extract the drum's surface normal (UP direction) from its transform.
        let transform = entity.transformMatrix(relativeTo: nil)
        let drumNormal = normalize(
            SIMD3<Float>(
                transform.columns.2.x,
                transform.columns.2.y,
                transform.columns.2.z
            )
        )

        // Project the hit direction onto the drum surface plane.
        let hitDirInPlane = rawHitDir - dot(rawHitDir, drumNormal) * drumNormal

        // If the hit is extremely close to the center, skip animation to avoid unstable axis calculations.
        guard simd_length_squared(hitDirInPlane) > 0.0001 else { return }

        // Normalized direction of the hit along the drum surface
        let hitDir = normalize(hitDirInPlane)

        // Compute a tilt axis perpendicular to both the drum normal and hit direction.
        // This causes the drum to tilt *away* from the impact point.
        let worldTiltAxis = normalize(cross(drumNormal, hitDir))

        // Convert the world-space axis into the drum’s local coordinate space
        let localTiltAxis = normalize(entity.convert(direction: worldTiltAxis, from: nil))

        // Distance from center to hit point (in-plane)
        let hitRadius = simd_length(hitDirInPlane)

        // Approximate drum radius using visual bounds (world space)
        let bounds = entity.visualBounds(relativeTo: nil)
        let radius = max(bounds.extents.x, bounds.extents.z) * 0.5

        // Normalize hit distance to a 0–1 range
        // Center hits produce little tilt; edge hits produce more.
        let radiusFactor = min(hitRadius / radius, 1.0)

        // Determine strike speed
        let rawSpeed = velocity ?? Config.defaultVelocity
        let clampedSpeed: Float = rawSpeed.clamped(to: 0.2...6.0)

        // Optional dampening factor for hi-hat behavior.
        // Closed hi-hat significantly reduces visible tilt.
        var hiHatFactor: Float? = nil
        if entity.name == DrumID.target_hi_hat_top.rawValue {
            hiHatFactor = appState.isHiHatClosed
                ? 0.03
                : max(0.03, footPedalManager.hiHat.distance)
        }

        // Final tilt angle:
        // - Proportional to strike speed
        // - Scaled by hit distance from center
        // - Dampened for hi-hat pedal state (if applicable)
        let angle = clampedSpeed * 0.05 * radiusFactor * (hiHatFactor ?? 1.0)

        // Construct a quaternion representing the tilt
        let tilt = simd_quatf(angle: angle, axis: localTiltAxis)

        // First animation: quick tilt away from the hit
        entity.move(
            to: Transform(rotation: tilt * restOrientation),
            relativeTo: entity.parent,
            duration: 0.05,
            timingFunction: .easeOut
        )

        // Second animation: smoothly return to rest orientation
        entity.move(
            to: Transform(rotation: restOrientation),
            relativeTo: entity.parent,
            duration: 0.3,
            timingFunction: .easeInOut
        )
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

    /// Runs every frame to update stick visibility and process strikes
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

    /// Process stick movement by raycasting from last to current tip position.
    /// This avoids tunneling issues at high speeds.
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

        if strikeSpeed < Config.minStrikeSpeed {
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

    /// Validates if raycast hit is a valid hit
    /// Filter for top-surface hits only and gates multiple hits while stick is inside the drum.
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

            // Accept only top-surface hits (0.7 ≈ within 45° of up) and gate double hits while inside.
            let isTopHit = dot(hit.normal, entityUp) > Config.topHitThreshold
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
