require 'xcodeproj'
project_path = 'Screen Mockup.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

main_group = project.main_group.children.find { |c| c.display_name == 'Screen Mockup' }

# Remove ContentView
if (content_view_ref = main_group.files.find { |f| f.path == 'ContentView.swift' })
  content_view_ref.remove_from_project
end

# Add groups and files
models_group = main_group.new_group('Models', 'Models')
file1 = models_group.new_reference('MockupDocument.swift')
target.add_file_references([file1])

editor_group = main_group.new_group('Editor', 'Editor')
file2 = editor_group.new_reference('EditorView.swift')
target.add_file_references([file2])

canvas_group = editor_group.new_group('Canvas', 'Canvas')
file3 = canvas_group.new_reference('MockupCanvasView.swift')
target.add_file_references([file3])

project.save
