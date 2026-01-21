#!/usr/bin/env ruby

require 'xcodeproj'

# Create a new project
project_path = 'WarpDriveApp/WarpDriveApp.xcodeproj'
project = Xcodeproj::Project.new(project_path)

# Create the main target
target = project.new_target(:application, 'WarpDriveApp', :ios, '17.0')

# Get the main group
main_group = project.main_group

# Create source files group
app_group = main_group.new_group('WarpDriveApp')

# Add source files
app_file = app_group.new_file('WarpDriveApp.swift')
target.source_build_phase.add_file_reference(app_file)

# Add Resources group
resources_group = app_group.new_group('Resources')
assets_file = resources_group.new_file('Resources/Assets.xcassets')
target.resources_build_phase.add_file_reference(assets_file)

# Set build configurations
target.build_configurations.each do |config|
  config.build_settings['PRODUCT_NAME'] = 'WarpDriveApp'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.warpdrive.app'
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  config.build_settings['INFOPLIST_FILE'] = 'Info.plist'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks'
  config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = config.name == 'Debug' ? '-Onone' : '-O'
end

# Note: Swift Package dependencies need to be added manually in Xcode
# or we can add framework references if needed

# Save the project
project.save

puts "Created Xcode project at #{project_path}"
