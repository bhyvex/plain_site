# encoding: utf-8


Gem::Specification.new do |s|
    s.name         = 'plain_site'
    s.version      = '0.0.1'
    s.license      = 'MIT'
    s.date         = '2013-08-25'
    s.author       = 'CJ'
    s.email        = 'i@jex.im'
    s.homepage     = 'https://github.com/jex-im/plain_site'
    s.summary      = 'A simple static site generator.'
    s.description  = 'PlainSite is a static site generator inspired by Jekyll and Octopress.'

    s.files        = Dir['**/*'].reject &(File.method :directory?)
    s.test_files   = s.files.select { |path| path =~ /^test\/.*_test\.rb/ }
    s.require_path = 'lib'
    s.bindir       = 'bin'
    s.executables  = ['plain_site']

    s.required_ruby_version = '>= 1.9.3'

    [
        'pygments.rb', '~> 0.5.1',
        'maruku', '~> 0.6.1',
        'safe_yaml', '~> 0.9.4',
        'grit', '~> 2.5.0',
        'rake', '~> 10.0.3',
        'rdoc', '~> 4.0.0',
        'commander', '~> 4.1.3',
        'listen', '~> 1.2.3'
    ].each_slice(2) do |a|
        s.add_runtime_dependency *a
    end



end
