#!/usr/bin/env ruby
# Script to add FlirtKeyboardExtension target to the Xcode project
# This runs on Codemagic after flutter create regenerates the iOS project
# Working directory: flutter_keyboard/

require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Check if target already exists
if project.targets.any? { |t| t.name == 'FlirtKeyboardExtension' }
  puts "FlirtKeyboardExtension target already exists, skipping..."
  exit 0
end

puts "Adding FlirtKeyboardExtension target..."

# Get the main app target
app_target = project.targets.find { |t| t.name == 'Runner' }
unless app_target
  puts "ERROR: Runner target not found!"
  exit 1
end

# Verify extension source files exist
unless File.exist?('ios/FlirtKeyboardExtension/KeyboardViewController.swift')
  puts "ERROR: FlirtKeyboardExtension source files not found at ios/FlirtKeyboardExtension/"
  exit 1
end

# Create the keyboard extension target
extension_target = project.new_target(
  :app_extension,
  'FlirtKeyboardExtension',
  :ios,
  '15.0'
)

# Ensure product reference has correct name and type
extension_target.product_reference.name = 'FlirtKeyboardExtension.appex'
extension_target.product_reference.path = 'FlirtKeyboardExtension.appex'

# Set build settings for extension (all configurations: Debug, Release, Profile)
extension_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_NAME'] = 'FlirtKeyboardExtension'
  config.build_settings['PRODUCT_MODULE_NAME'] = 'FlirtKeyboardExtension'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.desenrolaai.app.keyboard'
  config.build_settings['INFOPLIST_FILE'] = 'FlirtKeyboardExtension/Info.plist'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '13'
  config.build_settings['MARKETING_VERSION'] = '1.0.0'
  config.build_settings['SKIP_INSTALL'] = 'YES'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'FlirtKeyboardExtension/FlirtKeyboardExtension.entitlements'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/../../Frameworks'
  config.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
  config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = config.name == 'Debug' ? '-Onone' : '-O'
end

# Create file group for extension (path relative to ios/ project root)
extension_group = project.main_group.new_group('FlirtKeyboardExtension', 'FlirtKeyboardExtension')

# Add files to group (filenames only, group provides the directory context)
swift_files = Dir.glob('ios/FlirtKeyboardExtension/*.swift').map { |f| File.basename(f) }
plist_ref = extension_group.new_file('Info.plist')

swift_refs = swift_files.map { |f| extension_group.new_file(f) }

# Add source files to target's compile sources
extension_target.add_file_references(swift_refs)

# Create entitlements for keyboard extension
entitlements_content = <<~ENTITLEMENTS
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.desenrolaai.app.shared</string>
    </array>
</dict>
</plist>
ENTITLEMENTS

File.write('ios/FlirtKeyboardExtension/FlirtKeyboardExtension.entitlements', entitlements_content)

# Create Runner entitlements with App Groups
runner_entitlements_content = <<~ENTITLEMENTS
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.desenrolaai.app.shared</string>
    </array>
</dict>
</plist>
ENTITLEMENTS

File.write('ios/Runner/Runner.entitlements', runner_entitlements_content)

# Set entitlements for Runner target
app_target.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

# Add the extension as a dependency of the main app
app_target.add_dependency(extension_target)

# Embed the extension using a SHELL SCRIPT phase instead of PBXCopyFilesBuildPhase.
# PBXCopyFilesBuildPhase gets fused with "[CP] Embed Pods Frameworks" by Xcode's
# new build system, creating a dependency cycle with "Thin Binary".
# A shell script with explicit input/output paths avoids fusing entirely.
embed_script = app_target.new_shell_script_build_phase('Embed Keyboard Extension')
embed_script.shell_script = <<~'SCRIPT'
  EXTENSION="${BUILT_PRODUCTS_DIR}/FlirtKeyboardExtension.appex"
  DESTINATION="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/PlugIns"
  if [ -d "$EXTENSION" ]; then
    mkdir -p "$DESTINATION"
    rm -rf "$DESTINATION/FlirtKeyboardExtension.appex"
    cp -r "$EXTENSION" "$DESTINATION/"
    echo "Embedded FlirtKeyboardExtension.appex into PlugIns"
  else
    echo "error: FlirtKeyboardExtension.appex not found at $EXTENSION"
    exit 1
  fi
SCRIPT
embed_script.input_paths = ['$(BUILT_PRODUCTS_DIR)/FlirtKeyboardExtension.appex']
embed_script.output_paths = ['$(BUILT_PRODUCTS_DIR)/$(PRODUCT_NAME).app/PlugIns/FlirtKeyboardExtension.appex']

# Save project
project.save

puts "FlirtKeyboardExtension target added successfully!"
puts "  Bundle ID: com.desenrolaai.app.keyboard"
puts "  App Group: group.com.desenrolaai.app.shared"
puts "  Module Name: FlirtKeyboardExtension"
puts "  Embed method: Shell script (avoids Xcode fused phase cycle)"
