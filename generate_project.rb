require 'xcodeproj'
require 'fileutils'

project_path = 'StudyBuddy.xcodeproj'
FileUtils.rm_rf(project_path) if Dir.exist?(project_path)

project = Xcodeproj::Project.new(project_path)
target = project.new_target(:application, 'StudyBuddy', :ios, '17.0')

main_group = project.main_group.find_subpath(File.join('StudyBuddy.swiftpm'), true)
app_group = main_group

# Add all swift files
Dir.glob("StudyBuddy.swiftpm/*.swift").each do |file|
  file_ref = main_group.new_reference(File.basename(file))
  target.source_build_phase.add_file_reference(file_ref)
end

# Add assets
assets_ref = main_group.new_reference("Assets.xcassets")
target.resources_build_phase.add_file_reference(assets_ref)

# Add wav files and env
Dir.glob("StudyBuddy.swiftpm/*.{wav,env}").each do |file|
  file_ref = main_group.new_reference(File.basename(file))
  target.resources_build_phase.add_file_reference(file_ref)
end

# Add Local Supabase Package Dependency
pkg_ref = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
pkg_ref.relative_path = 'Packages/supabase-swift'
project.root_object.package_references << pkg_ref
pkg_prod = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
pkg_prod.product_name = 'Supabase'
pkg_prod.package = pkg_ref
target.package_product_dependencies << pkg_prod

# Build settings
target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_KEY_UIApplicationSceneManifest_Generation'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents'] = 'YES'
  config.build_settings['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'studybuddy.swiftpm.StudyBuddy'
  config.build_settings['DEVELOPMENT_TEAM'] = 'ZT7BLN8CZ5'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['PRODUCT_NAME'] = 'StudyBuddy'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  config.build_settings['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['MARKETING_VERSION'] = '1.0'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
end

project.save
puts "Successfully created StudyBuddy.xcodeproj"
