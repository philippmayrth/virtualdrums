# Virtual Drums

A virtual DrumKit that runs on the Apple Vision Pro.

<img src="virtualdrums/assets/icon/Marketing FULL.png" width="300" height="300">

Im Projekt Virtual Drums haben wir uns die Frage gestellt, wie zukunftstauglich VR-Technologie tatsächlich ist. Als Plattform nutzen wir die Apple Vision Pro, programmiert mit Swift. Am besten lässt sich Technik evaluieren, indem man sie praktisch ausprobiert – daher haben wir ein virtuelles Drum Kit entwickelt. Inspiriert vom klassischen Instrument soll es die Möglichkeit bieten, mit der Apple Vision Pro Musik zu machen.
Ein echtes Drum Kit zu ersetzen ist nicht Ziel dieses Projekts. Der eigentliche Mehrwert liegt darin, dass auch Musikerinnen und Musiker ohne Schlagzeugkenntnisse Beats für eigene Songs entwickeln können, ohne dabei auf die herkömmliche Drum-Sequenzer-Programmierung angewiesen zu sein.

## Required Software

This is a complex software, as such it requires a lot of specialized tools.

### Blender

3D modeling software, free.
https://www.blender.org/

### Affinity Designer

Professional design tool. Used to create the app icon. Free version available.
https://www.affinity.studio/en/graphic-design-software

### Logic Pro

Professional audio software, used for drum sounds. Free 90 day trial available.
https://www.apple.com/de/logic-pro/

### Exernal Project Files

Files in the `external` dir require external software to open/edit. Those files are the source for the assets (audio, images, ...) used in the app.

## App Icon

Files for the app icon can be found in the `icon` dir. There are two types. Prefixed with `App` are used inside of Xcode and prefixed with `Marketing` can be used on App Store Connect. There are @1 and @2 available for most. The background icon for use in the app is exported as JPG not as PNG like all others, that is becuase XCode otherwise throws an error due to alpha channel being present in that image.

## Drum Sets (3D Models)

Located in `assets`.

A **drum kit model** is provided as a `.usdz` file and can be imported as an `Entity`.
Each `.usdz` file may contain multiple drum pieces, **each with its own separate mesh**.
When imported, every drum piece becomes a `ModelEntity` that is a child of the root `Entity`.

The available drum pieces are defined in `DrumController.swift` under `DrumID`.

We currently have two drum sets with multiple modular drum pieces:

* `burgundy_drum.usdz`
  * [Burgundy Drum Kit by Opal 🥁](https://skfb.ly/oIXLv) (CC Attribution) (adjust for our needs in Blender)
  1. target_snare
  2. target_bass_drum
  3. target_floor_tom
  4. target_mid_tom
  5. target_high_tom
  6. target_hi_hat
  7. target_ride
  8. ~~target_crash~~
* `drum_kit.usdz`
  * [Drum Kit](https://skfb.ly/oZroJ) (CC Attribution) (adjust for our needs in Blender)
  1. target_snare
  2. target_bass_drum
  3. target_floor_tom
  4. target_mid_tom
  5. target_high_tom
  6. target_hi_hat
  7. target_ride
  8. target_crash

### Naming Convention

Each drum piece **must** follow this naming format: `target-[drum-piece-name]`
The prefix ensures we can validate the collision target and the drum piece suffix is to locate the correct sound.

### Editing `.usdz` in Blender

1. Import the `.usdz` file into Blender
2. Edit as needed
3. Export as **Universal Scene Description (.usd*)**
4. Rename the exported file from `.usdc` to `.usdz`

#### Important: Axis Orientation

We compare the raycast hit normal (strike direction) with the UP vector of the drum piece. Therefore the drum face (piece that should be hit) must point up!

Blender uses **Z-up**, while RealityKit uses **Y-up**. Because of this difference, models often need axis conversion before they can be used correctly in RealityKit.
An easy option is to **use Reality Composer Pro**:

1. Open the `.usdz` file in Reality Composer Pro.
2. In the *Layer Data* card, set the **Up Axis** to **Z**.
3. Export the corrected `.usdz` file.

## Drum Sound Kits

Located in `soundkit`.

Files must be named: `[soundkit-name]_target_[drum-piece-name]`
Example: `bite_target_hi_hat`

* Currently we have 3 sound kits
    * bite
    * kick
    * squeeze
* Each sound kit currently contains 8 sounds
* Every soundkit must have a sound for each drum piece.

The drum kits are defined in `ContentView.swift` under `DrumKitID`.

## Identifizierte Einschränkungen (Vision Pro 1, visionOS 26.0)

### 1. Einschränkungen der Fußinteraktion

* **Keine native Fußerkennung in RealityKit**
  RealityKit stellt derzeit keine Fußerkennung bereit. Dadurch ist eine Umsetzung von Fußpedalen (z. B. Bassdrum oder Hi-Hat) über Bilderkennung nicht möglich.

* **Kein Zugriff auf Kamerabilddaten**
  Der fehlende Zugriff auf das Rohbildmaterial der Kameras verhindert eine eigenständige Implementierung einer Fußerkennung.

* **Limitierte Eingabealternativen**

  * **Tastatur-Input** ist nur eingeschränkt nutzbar, da er Fokus benötigt, welcher häufig von anderen UI-Elementen belegt oder reserviert ist.
  * **SwiftUI Commands** benötigen zwar keinen Fokus, liefern jedoch keine Unterscheidung zwischen *Key Down* und *Key Press* Events. Diese Differenzierung ist jedoch essenziell, z. B. für die korrekte Abbildung eines Hi-Hat-Pedals.
  * **Simulation über einen Custom Game Controller** ist technisch möglich, stellt jedoch für Endnutzer keine praktikable Lösung dar.

### 2. Einschränkungen der Handerfassung

* Da das Spielen vollständig auf der Handerfassung basiert, müssen sich die Hände jederzeit im Sichtfeld der Kameras befinden.

  * Verdeckungen einer Hand durch die andere führen zu Erkennungsproblemen.
  * Trommeln, die außerhalb des Kamerasichtfelds platziert sind, können nicht zuverlässig bespielt werden.

### 3. Fehlendes haptisches Feedback

* Es existiert keinerlei physische Rückmeldung (Haptik oder Widerstand) bei erfolgreichen Schlägen, was das Spielgefühl deutlich von einem realen Instrument unterscheidet.

### 4. Limitierungen der Kollisionsdetektion in RealityKit

* **Eingeschränkte Kollisionsinformationen**
  Die native Collision Detection von RealityKit liefert, für an die Hand befestigte Entities, keine Informationen über die Richtung der Kollision oder die Aufprallgeschwindigkeit (Velocity).
  Dadurch ist sie nicht ausreichend geeignet, um ausschließlich Schläge auf das Trommelfell zu erkennen oder die Schlagsstärke realistisch zu berechnen.
  Kollisionen werden nicht kontinuierlich geprüft. Bei schnellen Bewegungen kann dies zu *Tunneling*-Effekten führen, bei denen Kollisionen vollständig verpasst werden.

* **Alternative Lösung**
  Eine manuelle Velocity-Berechnung in Kombination mit Raycasts aus RealityKit stellt eine deutlich zuverlässigere Alternative dar und liefert in der Praxis bessere Ergebnisse.
