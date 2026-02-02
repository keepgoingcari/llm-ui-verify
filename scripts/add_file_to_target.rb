require 'xcodeproj'

project_path = ARGV[0]
file_path = ARGV[1]
target_name = ARGV[2]

if project_path.nil? || file_path.nil? || target_name.nil?
  warn 'Usage: add_file_to_target.rb /path/to/App.xcodeproj /path/to/file.swift TargetName'
  exit 1
end

project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == target_name }
if target.nil?
  warn "Target not found: #{target_name}"
  exit 1
end

relative = Pathname.new(file_path).relative_path_from(Pathname.new(File.dirname(project_path))).to_s

# Find or create group path based on file_path
parts = relative.split(File::SEPARATOR)
file_name = parts.pop

parent = project.main_group
parts.each do |part|
  group = parent.children.find { |c| c.respond_to?(:name) && c.name == part }
  group ||= parent.new_group(part, part)
  parent = group
end

existing = parent.files.find { |f| f.path == relative }
ref = existing || parent.new_file(relative)

unless target.source_build_phase.files_references.include?(ref)
  target.add_file_references([ref])
end

project.save
puts "Added #{relative} to #{target_name}"
