# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "browsermob/proxy/version"

Gem::Specification.new do |s|
  s.name        = "browsermob-proxy"
  s.version     = BrowserMob::Proxy::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Eric Beland"]
  s.email       = ["ebeland@browserup.com"]
  s.homepage    = "http://github.com/browserup/browsermob-proxy-rb"
  s.summary     = %q{Ruby client for the BrowserMob and BrowserUp Proxy REST API}
  s.description = %q{Ruby client for the BrowserMob and BrowserUp Proxy REST API}
  s.license     = 'Apache-2.0'

  s.rubyforge_project = "browsermob-proxy-rb"

  s.add_runtime_dependency "rest-client"
  s.add_runtime_dependency "childprocess", "~> 0.5"
  s.add_runtime_dependency "multi_json", "~> 1.0"
  s.add_runtime_dependency "har"

  s.add_development_dependency "rspec", "~> 2.0"
  s.add_development_dependency "selenium-webdriver", "~> 3.7"
  s.add_development_dependency "rake", "~> 0.9.2"
  s.add_development_dependency "rack", "~> 1.5"
  s.add_development_dependency "puma"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
