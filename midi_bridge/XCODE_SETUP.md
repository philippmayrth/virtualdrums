# Adding New Files to Xcode Project

The MIDI Bridge integration includes two new Swift files that need to be added to your Xcode project:

## Files to Add

1. **MIDIBridgeClient.swift** - HTTP client for bridge communication
2. **MIDIBridgeSettingsView.swift** - Settings UI for bridge configuration

## How to Add Them

### Method 1: Drag and Drop (Recommended)

1. Open `virtualdrums.xcodeproj` in Xcode
2. In Finder, navigate to `../virtualdrums/`
3. Drag these files into Xcode's Project Navigator:
   - `MIDIBridgeClient.swift`
   - `WindowGroup/MIDIBridgeSettingsView.swift`
4. In the dialog that appears:
   - ✓ Check "Copy items if needed" (should already be unchecked since files are in place)
   - ✓ Check "Add to targets: virtualdrums"
   - Click "Finish"

### Method 2: File → Add Files (Alternative)

1. Open `virtualdrums.xcodeproj` in Xcode
2. Right-click on the `virtualdrums` folder in Project Navigator
3. Select "Add Files to virtualdrums..."
4. Navigate to and select:
   - `MIDIBridgeClient.swift`
   - `WindowGroup/MIDIBridgeSettingsView.swift`
5. Make sure "Add to targets: virtualdrums" is checked
6. Click "Add"

## Verify the Integration

After adding the files, build the project (⌘B) and verify:

1. No compilation errors
2. The "MIDI Bridge" tab appears in the app
3. You can switch to that tab and see the settings interface

## If You Get Build Errors

If you see errors like "Cannot find 'MIDIBridgeClient' in scope":

1. Verify both files are in the project navigator
2. Check that they have the target membership set to "virtualdrums"
   - Select the file in Project Navigator
   - Open the File Inspector (⌘⌥1)
   - Verify "virtualdrums" is checked under "Target Membership"
3. Clean Build Folder (⌘⇧K) and rebuild (⌘B)

## Modified Files

These existing files were also modified to integrate the bridge:

- `DrumController.swift` - Now sends drum hits to bridge
- `AppState.swift` - Now sends kit selection to bridge
- `ContentTabView.swift` - Added MIDI Bridge tab
- `Info.plist` - Added network permissions

No additional action needed for these files.
