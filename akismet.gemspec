# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{akismet}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael Hale"]
  s.date = %q{2009-06-05}
  s.description = %q{TODO}
  s.email = %q{mikehale@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README"
  ]
  s.files = [
    "LICENSE",
    "Rakefile",
    "VERSION.yml",
    "lib/akismet.rb",
    "spec/akismet_spec.rb",
    "spec/spec.opts",
    "spec/spec_helper.rb",
    "spec/spec_http.rb"
  ]
  s.homepage = %q{http://github.com/mikehale/akismet}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{TODO}
  s.test_files = [
    "spec/akismet_spec.rb",
    "spec/spec_helper.rb",
    "spec/spec_http.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
