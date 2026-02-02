#!/usr/bin/env ruby
require 'optparse'

options = {
  ui_tests_dir: nil,
  app_root: nil,
  out: nil
}

OptionParser.new do |opts|
  opts.on('--ui-tests-dir DIR') { |v| options[:ui_tests_dir] = v }
  opts.on('--app-root DIR') { |v| options[:app_root] = v }
  opts.on('--out FILE') { |v| options[:out] = v }
end.parse!

ui_tests_dir = options[:ui_tests_dir]
app_root = options[:app_root]
out_file = options[:out]

if ui_tests_dir.nil? || app_root.nil? || out_file.nil?
  warn 'Usage: static_preflight.rb --ui-tests-dir DIR --app-root DIR --out FILE'
  exit 1
end

unless Dir.exist?(ui_tests_dir)
  warn "UI tests dir not found: #{ui_tests_dir}"
  exit 1
end

unless Dir.exist?(app_root)
  warn "App root not found: #{app_root}"
  exit 1
end

test_files = Dir.glob(File.join(ui_tests_dir, '**', '*.swift'))
if test_files.empty?
  warn "No UI test files found in #{ui_tests_dir}"
  exit 1
end

id_pattern = /
  app\.
  (?:buttons|textFields|secureTextFields|staticTexts|otherElements|tables|cells|navigationBars)
  \s*\[\s*"([^"]+)"\s*\]
/x

ids = []
test_files.each do |file|
  content = File.read(file)
  content.scan(id_pattern) { |m| ids << m[0] }
  content.scan(/matching\s*\(\s*identifier:\s*"([^"]+)"\s*\)/) { |m| ids << m[0] }
end

ids = ids.uniq.sort

missing = []
ids.each do |id|
  pattern = /accessibilityIdentifier\(\s*"#{Regexp.escape(id)}"\s*\)/
  found = false
  Dir.glob(File.join(app_root, '**', '*.swift')).each do |file|
    if File.read(file).match?(pattern)
      found = true
      break
    end
  end
  missing << id unless found
end

File.write(out_file, ids.join("\n"))

if missing.any?
  warn "Missing accessibility identifiers:\n" + missing.map { |m| "  - #{m}" }.join("\n")
  exit 2
end

puts "Static preflight ok (#{ids.size} identifiers)"
