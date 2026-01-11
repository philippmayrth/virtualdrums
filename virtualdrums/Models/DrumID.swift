//
//  DrumID.swift
//  virtualdrums
//
//  Created by Oliver Kühle on 11.01.26.
//

/// Identifies an individual drum or cymbal within a drum kit.
/// 
/// DrumID is used across the entire system: RealityKit entities, AudioEngine sample routing, MIDI output, Input mapping (sticks, pedals, gestures), etc.
/// Some IDs represent physical drums in the scene, while others represent specific sound variants (e.g. hi-hat open/closed).
enum DrumID: String, CaseIterable {
    case target_snare
    case target_bass_drum /// "kick"
    case target_floor_tom
    case target_mid_tom
    case target_high_tom
    case target_hi_hat_top /// Hi-hat 3D model. Not a sound — it is the physical target.
    case target_hi_hat_open /// Hi-hat sound when struck with the stick while open.
    case target_hi_hat_closed /// Hi-hat sound when struck with the stick while closed.
    case target_hi_hat_chick /// Hi-hat sound produced by the foot pedal (“chick”).
    case target_ride
    case target_crash
}
