import Foundation
import ARKit
import Combine
import simd

@MainActor
final class HandGripManager: ObservableObject {

    static let shared = HandGripManager()

    @Published private(set) var isLeftHandGripping = false
    @Published private(set) var isRightHandGripping = false

    private let gripThreshold: Float = 0.12

    func update(from anchor: HandAnchor) {
        let isGripping = computeGrip(anchor: anchor)
        
        switch anchor.chirality {
        case .left:
            isLeftHandGripping = isGripping
        case .right:
            isRightHandGripping = isGripping
        }
    }

    /// Determines whether the hand is in a gripping (fist) state suitable for holding a drum stick.
    ///
    /// Grip detection is based on fingertip-to-palm distance.
    ///
    /// The index finger must be curled for a grip to be considered valid, as an extended index finger
    /// causes stick tip raycasts to become unreliable, leading to missed drum hit detection.
    ///
    /// The remaining fingers (middle, ring, little) are evaluated collectively using their
    /// average distance to confirm the hand is generally closed, while allowing natural variation
    /// in finger posture.
    ///
    /// - Parameter anchor: The hand anchor providing joint positions for the current frame.
    /// - Returns: `true` if the hand is considered gripping and collision detection is reliable; otherwise `false`.
    private func computeGrip(anchor: HandAnchor) -> Bool {
        guard
            let palm = palmCenter(from: anchor),
            let indexTip = jointPosition(.indexFingerTip, in: anchor),
            let middleTip = jointPosition(.middleFingerTip, in: anchor),
            let ringTip = jointPosition(.ringFingerTip, in: anchor),
            let littleTip = jointPosition(.littleFingerTip, in: anchor)
        else {
            return false
        }

        let indexDistance = distance(indexTip, palm)
        let otherDistances = [
            distance(middleTip, palm),
            distance(ringTip, palm),
            distance(littleTip, palm)
        ]
        let otherAverage = otherDistances.reduce(0, +) / Float(otherDistances.count)

        let indexCurled = indexDistance < gripThreshold
        let otherCurled = otherAverage < gripThreshold
        
        return indexCurled && otherCurled
    }

    // MARK: - Palm approximation

    /// Approximates the center of the palm using the base joints of the index, middle, and ring fingers.
    /// The resulting position is in the hand-anchor space.
    private func palmCenter(from anchor: HandAnchor) -> SIMD3<Float>? {
        guard
            let index = jointPosition(.indexFingerMetacarpal, in: anchor),
            let middle = jointPosition(.middleFingerMetacarpal, in: anchor),
            let ring = jointPosition(.ringFingerMetacarpal, in: anchor)
        else { return nil }
        return (index + middle + ring) / 3
    }

    // MARK: - Joint access

    /// Returns the position of the specified hand joint in hand-anchor space.
    private func jointPosition(_ joint: HandSkeleton.JointName, in anchor: HandAnchor) -> SIMD3<Float>? {
        guard let joint = anchor.handSkeleton?.joint(joint) else { return nil }
        let t = joint.anchorFromJointTransform
        return SIMD3<Float>(t.columns.3.x, t.columns.3.y, t.columns.3.z)
    }
}
