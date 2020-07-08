lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "graphiti/graphql/version"

Gem::Specification.new do |spec|
  spec.name = "graphiti-graphql"
  spec.version = Graphiti::GraphQL::VERSION
  spec.authors = ["Zach Schneider"]
  spec.email = ["zach@aha.io"]

  spec.summary = "Automatically generate a GraphQL API from your Graphiti resources"
  spec.homepage = "https://github.com/aha-app/graphiti-graphql"
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 4.1"
  spec.add_dependency "graphiti", "~> 1.2.17"
  spec.add_dependency "graphiti-rails", "~> 0.2.3"
  spec.add_dependency "graphql", "~> 1.11.1"
  spec.add_dependency "graphql-batch", "~> 0.4.3"

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "graphiti_spec_helpers"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "kaminari"
  spec.add_development_dependency "database_cleaner-active_record"
  spec.add_development_dependency "simplecov"
end
