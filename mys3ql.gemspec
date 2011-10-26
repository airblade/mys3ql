# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mys3ql/version"

Gem::Specification.new do |s|
  s.name        = "mys3ql"
  s.version     = Mys3ql::VERSION
  s.authors     = ["Andy Stewart"]
  s.email       = ["boss@airbladesoftware.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "mys3ql"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'fog', '~> 1.0.0'
end
