# Virtual Drums

## Required Software

This is a complex software, as such it requires a lot of specialized tools.

### Blender

3D modeling software, free.
https://www.blender.org/

## Affinity Designer

Professional design tool. Used to create the app icon. Free version available.
https://www.affinity.studio/en/graphic-design-software

## Logic Pro

Professional audio software, used for drum sounds. Free 90 day trial available.
https://www.apple.com/de/logic-pro/

## Project Structure

Files in the `external` dir require external software to open/edit. Those files are the source for the assets (audio, images, ...) used in the app.

### App Icon

Files for the app icon can be found in the `icon` dir. There are two types. Prefixed with `App` are used inside of Xcode and prexied with `Marketing` can be used on App Sotre Connect. There are @1 and @2 available for most. The background icon for use in the app is exported as JPG not as PNG like all others, that is becuase XCode otherwise throws an error due to alpha channel being present in that image.

### Drum Sounds

Found in `soundkit`. All files are prefixed with the name of the drum kit sound they represent. There are currently 8 sounds per soundkit.

### DrumKit

The drumkit asset is currently `DrumKit_Named` it was the only free model on sketchfab (https://sketchfab.com/3d-models/drum-kit-57f6bb6e93c14762b0da1be2a50f1f44) that had objects named so sound could be mapped on it.
