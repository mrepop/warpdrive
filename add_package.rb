#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'WarpDriveApp/WarpDriveApp.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the target
target = project.targets.first

# Add local package reference
package_ref = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
package_ref.relative_path = '..'
project.root_object.package_references << package_ref

# Add package product dependency
product_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
product_dep.product_name = 'WarpDriveCore'
product_dep.package = package_ref

# Add to target
target.package_product_dependencies << product_dep

# Save
project.save

puts "Added WarpDriveCore package dependency"
