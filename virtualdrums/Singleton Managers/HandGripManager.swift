import Foundation
import ARKit
import Combine
import simd

/// Tracks whether each hand is gripping (closed fist) in a way that is reliable for drum-stick collision and hit detection.
@MainActor
final class HandGripManager: ObservableObject {

    static let shared = HandGripManager()

    // MARK: - Public Grip State

    @Published private(set) var isLeftHandGripping = false
    @Published private(set) var isRightHandGripping = false

    // MARK: - Tuning Parameters

    /// Maximum fingertip-to-palm distance for a finger/hand to be considered curled.
    private let gripThreshold: Float = 0.135

    /// How long the hand must remain open before a grip is released.    
    private let releaseDelay: UInt64 = 300_000_000 // 300 ms

    // MARK: - Internal State

    private var pendingReleaseTasks: [HandAnchor.Chirality: Task<Void, Never>] = [:]

    // MARK: - Per-Frame Update

    /// Updates grip state for the provided hand anchor.
    /// Call this once per tracking frame for each detected hand.
    func update(for anchor: HandAnchor) {
        let isGripping = isHandGripping(anchor)
        updateGripState(to: isGripping, for: anchor.chirality)
    }

    // MARK: - Grip State Machine

    /// Converts raw per-frame grip detection into a stable, debounced grip state.
    ///
    /// Grip detection can fluctuate due to tracking noise and fast finger motion.
    /// A detected fist is applied immediately, while a detected release is only applied after a short delay to prevent flicker and unintended dropouts.
    private func updateGripState(
        to isGripping: Bool,
        for hand: HandAnchor.Chirality
    ) {

        let wasGripping = getGripState(for: hand)

        if isGripping {
            // The hand is closed -> cancel any pending release
            cancelPendingRelease(for: hand)
            
            // Only publish if state changed
            if !wasGripping {
                setGripState(to: true, for: hand)
            }
        }
        else if wasGripping {
            // The hand has opened -> start a delayed release
            scheduleDelayedRelease(for: hand)
        }
    }

    /// Starts a delayed task that will release the grip if the hand remains open long enough.
    private func scheduleDelayedRelease(for hand: HandAnchor.Chirality) {
        cancelPendingRelease(for: hand)

        pendingReleaseTasks[hand] = Task {
            try? await Task.sleep(nanoseconds: releaseDelay)
            setGripState(to: false, for: hand)
        }
    }
    
    private func cancelPendingRelease(for hand: HandAnchor.Chirality) {
        pendingReleaseTasks[hand]?.cancel()
        pendingReleaseTasks[hand] = nil
    }

    private func getGripState(for hand: HandAnchor.Chirality) -> Bool {
        switch hand {
        case .left:  return isLeftHandGripping
        case .right: return isRightHandGripping
        }
    }

    private func setGripState(to isGripping: Bool, for hand: HandAnchor.Chirality) {
        switch hand {
        case .left:  isLeftHandGripping = isGripping
        case .right: isRightHandGripping = isGripping
        }
    }

    // MARK: - Grip Detection

    /// Determines whether a hand is in a valid fist posture for stick tracking.
    ///
    /// A full fist is required for reliable drum interaction. With an open hand, the collision detection becomes unstable for unknown reason and stick-tip raycasts fail to register drum hits.
    /// In particular, the index finger must be curled. It is evaluated independently because extending only the index finger would otherwise be masked by the other curled fingers when averaging.
    /// The remaining fingers (middle, ring, and little) are averaged together to confirm that the rest of the hand is generally closed, while still allowing for natural variation.
    private func isHandGripping(_ anchor: HandAnchor) -> Bool {
        guard
            let palmCenter = palmCenter(from: anchor),
            let indexTip = position(of: .indexFingerTip, from: anchor),
            let middleTip = position(of: .middleFingerTip, from: anchor),
            let ringTip = position(of: .ringFingerTip, from: anchor),
            let littleTip = position(of: .littleFingerTip, from: anchor)
        else { return false }

        let indexToPalm = distance(indexTip, palmCenter)

        let otherFingerDistances = [
            distance(middleTip, palmCenter),
            distance(ringTip, palmCenter),
            distance(littleTip, palmCenter)
        ]

        let averageOtherFingerDistance =
            otherFingerDistances.reduce(0, +) / Float(otherFingerDistances.count)

        let isIndexCurled = indexToPalm < gripThreshold
        let isOtherFingersCurled = averageOtherFingerDistance < gripThreshold

        return isIndexCurled && isOtherFingersCurled
    }

    // MARK: - Palm Approximation

    /// Approximates the center of the palm using the metacarpal bases of the index, middle, and ring fingers.
    /// Returns the position in hand-anchor space.
    private func palmCenter(from anchor: HandAnchor) -> SIMD3<Float>? {
        guard
            let index = position(of: .indexFingerMetacarpal, from: anchor),
            let middle = position(of: .middleFingerMetacarpal, from: anchor),
            let ring = position(of: .ringFingerMetacarpal, from: anchor)
        else { return nil }

        return (index + middle + ring) / 3
    }

    // MARK: - Joint Access

    /// Returns the position of a hand joint in hand-anchor space.
    private func position(of name: HandSkeleton.JointName, from anchor: HandAnchor) -> SIMD3<Float>? {
        guard let joint = anchor.handSkeleton?.joint(name) else { return nil }
        let t = joint.anchorFromJointTransform
        return SIMD3(t.columns.3.x, t.columns.3.y, t.columns.3.z)
    }
}
