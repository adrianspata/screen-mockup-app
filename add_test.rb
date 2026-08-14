require 'xcodeproj'

project_path = 'Screen Mockup.xcodeproj'
project = Xcodeproj::Project.open(project_path)

test_target = project.targets.find { |t| t.name == 'Screen MockupTests' }
group = project.main_group.find_subpath(File.join('Screen MockupTests'), true)

file_path = 'Screen MockupTests/Phase72ATests.swift'
file_ref = group.new_reference(file_path)
test_target.source_build_phase.add_file_reference(file_ref)

project.save
puts "Added #{file_path} to target #{test_target.name}"
