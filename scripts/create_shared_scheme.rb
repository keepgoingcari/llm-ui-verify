require 'xcodeproj'

project_path = ARGV[0]
app_target_name = ARGV[1] || 'HappyTrigger'

if project_path.nil? || project_path.empty?
  warn "Usage: create_shared_scheme.rb /path/to/App.xcodeproj [AppTargetName]"
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

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app_target)

scheme.test_action = Xcodeproj::XCScheme::TestAction.new
scheme.test_action.build_configuration = 'Debug'

[unit_target, ui_target].compact.each do |t|
  ref = Xcodeproj::XCScheme::TestAction::TestableReference.new(t)
  scheme.test_action.add_testable(ref)
end

scheme.launch_action = Xcodeproj::XCScheme::LaunchAction.new
scheme.launch_action.build_configuration = 'Debug'

scheme.profile_action = Xcodeproj::XCScheme::ProfileAction.new
scheme.profile_action.build_configuration = 'Release'

scheme.analyze_action = Xcodeproj::XCScheme::AnalyzeAction.new
scheme.analyze_action.build_configuration = 'Debug'

scheme.archive_action = Xcodeproj::XCScheme::ArchiveAction.new
scheme.archive_action.build_configuration = 'Release'

scheme.save_as(project_path, app_target_name, true)
puts "Saved shared scheme: #{app_target_name}"
