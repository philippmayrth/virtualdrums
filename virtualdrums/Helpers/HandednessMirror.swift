import RealityKit

extension Entity {

    /// Mirrors the entity horizontally to support left handedness.
    ///
    /// This file looks complicated, however it simply flips the (+/-) sign for position.x, rotation.y and rotation.z
    /// Using a negative scale tranformation might be simpler, but breaks materials, lighting, and physics.
    func applyLeftHandednessMirror() {
        // 1. Mirror position on X
        var pos = transform.translation
        pos.x *= -1
        transform.translation = pos

        // 2. Convert rotation to Euler
        let euler = transform.rotation.toEulerAngles()

        // 3. Flip signs (mirror)
        let mirroredEuler = SIMD3<Float>(
            euler.x,
            -euler.y,
            -euler.z
        )

        // 4. Convert back to quaternion
        transform.rotation = simd_quatf(euler: mirroredEuler)
    }
}

extension simd_quatf {

    /// Converts quaternion to Euler angles (XYZ order, radians)
    func toEulerAngles() -> SIMD3<Float> {
        let q = normalized

        let sinr_cosp = 2 * (q.real * q.imag.x + q.imag.y * q.imag.z)
        let cosr_cosp = 1 - 2 * (q.imag.x * q.imag.x + q.imag.y * q.imag.y)
        let x = atan2(sinr_cosp, cosr_cosp)

        let sinp = 2 * (q.real * q.imag.y - q.imag.z * q.imag.x)
        let y = abs(sinp) >= 1
            ? copysign(.pi / 2, sinp)
            : asin(sinp)

        let siny_cosp = 2 * (q.real * q.imag.z + q.imag.x * q.imag.y)
        let cosy_cosp = 1 - 2 * (q.imag.y * q.imag.y + q.imag.z * q.imag.z)
        let z = atan2(siny_cosp, cosy_cosp)

        return SIMD3(x, y, z)
    }
}

extension simd_quatf {

    /// Creates quaternion from Euler angles (XYZ order, radians)
    init(euler angles: SIMD3<Float>) {
        let cx = cos(angles.x / 2)
        let sx = sin(angles.x / 2)
        let cy = cos(angles.y / 2)
        let sy = sin(angles.y / 2)
        let cz = cos(angles.z / 2)
        let sz = sin(angles.z / 2)

        self.init(
            ix: sx * cy * cz + cx * sy * sz,
            iy: cx * sy * cz - sx * cy * sz,
            iz: cx * cy * sz + sx * sy * cz,
            r:  cx * cy * cz - sx * sy * sz
        )
    }
}
