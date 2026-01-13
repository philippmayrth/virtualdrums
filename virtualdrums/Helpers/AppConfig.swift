import CoreFoundation

enum Config {

    // App State
    static let defaultSelectedDrumKit: DrumKitID = .accoustic
    static let defaultSelectedDrumSet: DrumSetID = .burgundy_drum


    // WindowGroup UI
    static let tabViewWidth: CGFloat = 600
    static let tabViewHeight: CGFloat = 450

    
    // Immersive Space
    static let drumSetPosition: SIMD3<Float> = [0, 0.15, -0.6]

    // Audio
    static let defaultMaxPolyphony: Int = 8
    
    static let minVolume: Float = 0.0
    static let defaultVolume: Float = 1.0
    static let maxVolume: Float = 3.0


    // Velocity
    static let minVelocity: Float = 0.0
    static let defaultVelocity: Float = 7.5
    static let maxVelocity: Float = 15.0


    // Drum Stick
    static let stickHandleLength: Float = 0.25
    static let stickHandleRadius: Float = 0.004
    static let stickTipRadius: Float = 0.005


    // Hit Detection
    static let minStrikeSpeed: Float = 0.3
    static let topHitThreshold: Float = 0.7


    // Hand Grip Detection
    /// Maximum fingertip-to-palm distance for a finger/hand to be considered curled.
    static let handGripThreshold: Float = 0.135
    /// How long the hand must remain open before a grip is released.
    static let handGripReleaseDelay: UInt64 = 300_000_000  // 300 ms


    // MIDI Bridge
    /// Bridge server URL
    static let MIDIBaseURL = "http://localhost:5729"


    #if targetEnvironment(simulator)
        // Simulator Debugging
        static let simulatorStickRadius: Float = 0.01
        static let simulatorRestPosition: SIMD3<Float> = [0, 0.35, -0.35]
        static let simulatorSweepDistance: Float = 0.3
        static let simulatorSweepDurationSeconds: Double = 1.0
        static let simulatorMoveStep: Float = 0.02
    #endif

}
