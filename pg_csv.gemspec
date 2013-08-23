$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "pg_csv/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "pg_csv"
  s.version     = PgCsv::VERSION
  s.authors     = ["Makarchev Konstantin"]
  s.email       = ["kostya27@gmail.com"]
  s.homepage    = "http://github.com/kostya/pg_csv"
  s.summary     = "Fast AR/PostgreSQL csv export. Used pg function 'copy to csv'. Effective on millions rows."
  s.description = "Fast AR/PostgreSQL csv export. Used pg function 'copy to csv'. Effective on millions rows."

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency "pg"
  s.add_dependency "activerecord"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
  
end