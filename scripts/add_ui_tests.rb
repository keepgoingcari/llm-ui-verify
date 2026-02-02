require 'xcodeproj'

project_path = ARGV[0]
app_target_name = ARGV[1] || 'HappyTrigger'
ui_target_name = ARGV[2] || 'HappyTriggerUITests'

if project_path.nil? || project_path.empty?
  warn "Usage: add_ui_tests.rb /path/to/App.xcodeproj [AppTargetName] [UITestTargetName]"
  exit 1
end

project = Xcodeproj::Project.open(project_path)
app_target = project.targets.find { |t| t.name == app_target_name }
if app_target.nil?
  warn "App target not found: #{app_target_name}"
  exit 1
end

existing = project.targets.find { |t| t.name == ui_target_name }
if existing
  puts "UI test target already exists: #{ui_target_name}"
  exit 0
end

deployment = app_target.build_configurations.first.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] || '17.0'
ui_target = project.new_target(:ui_test_bundle, ui_target_name, :ios, deployment)
ui_target.add_dependency(app_target)

app_build = app_target.build_configurations.first.build_settings
ui_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.happytrigger.HappyTriggerUITests'
  config.build_settings['INFOPLIST_FILE'] = 'HappyTriggerUITests/Info.plist'
  config.build_settings['SWIFT_VERSION'] = app_build['SWIFT_VERSION'] || '5.0'

  if app_build['DEVELOPMENT_TEAM']
    config.build_settings['DEVELOPMENT_TEAM'] = app_build['DEVELOPMENT_TEAM']
  end
  if app_build['CODE_SIGN_STYLE']
    config.build_settings['CODE_SIGN_STYLE'] = app_build['CODE_SIGN_STYLE']
  end
  if app_build['CODE_SIGN_IDENTITY']
    config.build_settings['CODE_SIGN_IDENTITY'] = app_build['CODE_SIGN_IDENTITY']
  end
end

group = project.main_group.find_subpath('HappyTriggerUITests', true)
group.set_source_tree('SOURCE_ROOT')

host_test = group.new_file('HappyTriggerUITests/HostFlowTests.swift')
ui_target.add_file_references([host_test])

group.new_file('HappyTriggerUITests/Info.plist')

project.save
puts "Created UI test target: #{ui_target_name}"
