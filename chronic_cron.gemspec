Gem::Specification.new do |s|
  s.name = 'chronic_cron'
  s.version = '0.7.1'
  s.summary = 'Converts a human-readable time (e.g. 10:15 daily) into a ' + 
      'cron format (e,g, 15 10 * * *)'
  s.authors = ['James Robertson']
  s.files = Dir['lib/chronic_cron.rb'] 
  s.add_runtime_dependency('app-routes', '~> 0.1', '>=0.1.19')
  s.add_runtime_dependency('cron_format', '~> 0.6', '>=0.6.0')
  s.add_runtime_dependency('chronic', '~> 0.10', '>=0.10.2')
  s.add_runtime_dependency('timetoday', '~> 0.2', '>=0.2.0')
  s.signing_key = '../privatekeys/chronic_cron.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/chronic_cron'
  s.required_ruby_version = '>= 2.1.2'
end
