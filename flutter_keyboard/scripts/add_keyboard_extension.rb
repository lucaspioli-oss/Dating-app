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

# Create the keyboard extension target
extension_target = project.new_target(
  :app_extension,
  'FlirtKeyboardExtension',
  :ios,
  '15.0'
)

# Get DEVELOPMENT_TEAM from main target
dev_team = ''
app_target.build_configurations.each do |config|
  team = config.build_settings['DEVELOPMENT_TEAM']
  if team && !team.empty?
    dev_team = team
    break
  end
end

# Set build settings for extension
extension_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.desenrolaai.app.keyboard'
  config.build_settings['INFOPLIST_FILE'] = 'FlirtKeyboardExtension/Info.plist'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
  config.build_settings['DEVELOPMENT_TEAM'] = dev_team
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  config.build_settings['MARKETING_VERSION'] = '1.0'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'FlirtKeyboardExtension/FlirtKeyboardExtension.entitlements'
end

# Create file group for extension (path relative to ios/)
extension_group = project.main_group.new_group('FlirtKeyboardExtension', 'FlirtKeyboardExtension')

# Add files to group (filenames only, group provides the directory context)
swift_ref = extension_group.new_file('KeyboardViewController.swift')
plist_ref = extension_group.new_file('Info.plist')

# Add source file to target's compile sources
extension_target.add_file_references([swift_ref])

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

# Write entitlements (paths relative to working dir flutter_keyboard/)
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

# Add "Embed App Extensions" copy phase
embed_phase = app_target.new_copy_files_build_phase('Embed App Extensions')
embed_phase.dst_subfolder_spec = '13' # PlugIns folder
embed_phase.add_file_reference(extension_target.product_reference, true)

# Save project
project.save

puts "FlirtKeyboardExtension target added successfully!"
puts "  Bundle ID: com.desenrolaai.app.keyboard"
puts "  App Group: group.com.desenrolaai.app.shared"
puts "  Entitlements: FlirtKeyboardExtension.entitlements + Runner.entitlements"
