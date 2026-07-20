require 'xcodeproj'

project_path = 'StudyBuddy.xcodeproj'
project = Xcodeproj::Project.new(project_path)

# Add iOS app target
target = project.new_target(:application, 'StudyBuddy', :ios, '16.0')

# Create groups
main_group = project.main_group.find_subpath(File.join('StudyBuddy'), true)
app_group = project.main_group.find_subpath(File.join('StudyBuddyApp'), true)

# Add source files
app_file = main_group.new_file('StudyBuddyApp.swift')
content_view_file = main_group.new_file('ContentView.swift')
web_view_file = main_group.new_file('WebView.swift')
env_file = main_group.new_file('.env')

# Add files to target
target.add_file_references([app_file, content_view_file, web_view_file])

# Add Info.plist
info_plist = main_group.new_file('Info.plist')
target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_FILE'] = 'StudyBuddy/Info.plist'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.studybuddy.mobile'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['PRODUCT_NAME'] = 'StudyBuddy'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  config.build_settings['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['MARKETING_VERSION'] = '1.0'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
end

project.save
puts "Successfully created StudyBuddy.xcodeproj"
