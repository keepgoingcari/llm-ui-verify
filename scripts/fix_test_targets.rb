require 'xcodeproj'

project_path = ARGV[0]
app_target_name = ARGV[1] || 'HappyTrigger'

if project_path.nil? || project_path.empty?
  warn "Usage: fix_test_targets.rb /path/to/App.xcodeproj [AppTargetName]"
  exit 1
end

project = Xcodeproj::Project.open(project_path)
app_target = project.targets.find { |t| t.name == app_target_name }
unit_target = project.targets.find { |t| t.name == "#{app_target_name}Tests" }
ui_target = project.targets.find { |t| t.name == "#{app_target_name}UITests" }

if app_target.nil?
  warn "App target not found: #{app_target_name}"
  exit 1
end

[unit_target, ui_target].compact.each do |t|
  t.build_configurations.each do |config|
    config.build_settings['SWIFT_VERSION'] = '5.0' if config.build_settings['SWIFT_VERSION'].to_s.empty?
  end
end

if unit_target
  unit_target.build_configurations.each do |config|
    config.build_settings['PRODUCT_NAME'] = unit_target.name
  end
end

if ui_target
  ui_target.build_configurations.each do |config|
    config.build_settings['PRODUCT_NAME'] = ui_target.name
    config.build_settings['TEST_TARGET_NAME'] = app_target.name
  end
end

project.save
puts "Updated test target settings"
