Gem::Specification.new do |s|
  s.name = 'chronic_cron'
  s.version = '0.3.3'
  s.summary = 'chronic_cron'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb'] 
  s.add_runtime_dependency('app-routes', '~> 0.1', '>=0.1.18')
  s.add_runtime_dependency('cron_format', '~> 0.2', '>=0.2.0')
  s.add_runtime_dependency('chronic', '~> 0.10', '>=0.10.2')
  s.add_runtime_dependency('timetoday', '~> 0.1', '>=0.1.9')
  s.signing_key = '../privatekeys/chronic_cron.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/chronic_cron'
  s.required_ruby_version = '>= 2.1.2'
end
