require "bundler/gem_tasks"
require "rake/clean"
require "rake/testtask"
require "rbconfig"

CLEAN.include(
  "**/*.gem",               # Gem files
  "**/*.rbc",               # Rubinius
  "**/*.o",                 # C object file
  "**/*.log",               # Ruby extension build log
  "**/Makefile",            # C Makefile
  "**/*.def",               # Definition files
  "**/*.exp",
  "**/*.lib",
  "**/*.pdb",
  "**/*.obj",
  "**/*.stackdump",         # Junk that can happen on Windows
  "**/*.#{RbConfig::CONFIG["DLEXT"]}", # C shared object
  "**/tmp/"
)

require "rake/extensiontask"

spec = Gem::Specification.load("chef-win32-api.gemspec")

def configure_cross_compilation(ext)
  unless RUBY_PLATFORM =~ /mswin|mingw/
    ext.cross_compile = true
    ext.cross_platform = %w{x64-mingw32 x64-mingw-ucrt}
  end
end

Rake::ExtensionTask.new("win32/api", spec) do |ext|
  ext.ext_dir = "ext/win32"
  ext.lib_dir = "lib/win32"
  configure_cross_compilation(ext)
end

desc "Check Linting and code style."
task :style do
  require "rubocop/rake_task"
  require "cookstyle/chefstyle"

  if RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/
    # Windows-specific command, rubocop erroneously reports the CRLF in each file which is removed when your PR is uploaeded to GitHub.
    # This is a workaround to ignore the CRLF from the files before running cookstyle.
    sh "cookstyle --chefstyle -c .rubocop.yml --except Layout/EndOfLine"
  else
    sh "cookstyle --chefstyle -c .rubocop.yml"
  end
rescue LoadError
  puts "Rubocop or Cookstyle gems are not installed. bundle install first to make sure all dependencies are installed."
end

namespace "test" do
  Rake::TestTask.new(:all) do |test|
    test.libs << "test"
    test.libs << "lib"
    test.warning = true
    test.verbose = true
  end

  Rake::TestTask.new(:callback) do |test|
    test.test_files = FileList["test/test_win32_api_callback.rb"]
    test.libs << "test"
    test.libs << "lib"
    test.warning = true
    test.verbose = true
  end

  Rake::TestTask.new(:function) do |test|
    test.test_files = FileList["test/test_win32_api_function.rb"]
    test.libs << "ext"
    test.warning = true
    test.verbose = true
  end
end

task default: %w{clobber compile test:all}
