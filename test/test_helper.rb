require 'minitest/autorun'
require 'rubygems/comparator'

# The tests expects these permissions, which isn't the case if you have
# umask 022 when cloning the repo
def setup_file_permissions
  gemfiles_path = File.expand_path('gemfiles', File.dirname(__FILE__))
  File.chmod(0664, File.join(gemfiles_path, 'lorem-0.0.1', 'lib', 'lorem.rb'))
  File.chmod(0664, File.join(gemfiles_path, 'lorem-0.0.3', 'bin', 'lorem'))
  File.chmod(0664, File.join(gemfiles_path, 'lorem-0.0.4', 'lib', 'lorem.rb'))
  File.chmod(0775, File.join(gemfiles_path, 'lorem-0.0.4', 'bin', 'lorem'))
end

def temp_bin_file
  bin_dir = File.join(Dir.mktmpdir, "bin")
  Dir.mkdir(bin_dir)
  Tempfile.new("", bin_dir)
end

class TestGemComparator < Minitest::Test
  def setup
    super

    setup_file_permissions

    options = { keep_all: true, log_all: true, no_color: true, brief_mode: false }
    versions = ['0.0.1', '0.0.2', '0.0.3', '0.0.4']

    @comparator = Gem::Comparator.new(options)

    Dir.chdir(File.expand_path('gemfiles', File.dirname(__FILE__))) do
      @comparator.options.merge!({ output: Dir.getwd })
      @comparator.compare_versions('lorem', versions)
    end

    @report = @comparator.report
  end
end

class TestGemModule < Minitest::Test
  def setup
    super
    Rainbow.enabled = false
    setup_file_permissions
    gemfiles_path = File.expand_path('gemfiles', File.dirname(__FILE__))
    @v001 = File.join(gemfiles_path, 'lorem-0.0.1')
    @v002 = File.join(gemfiles_path, 'lorem-0.0.2')
    @v003 = File.join(gemfiles_path, 'lorem-0.0.3')
    @v004 = File.join(gemfiles_path, 'lorem-0.0.4')
  end
end
