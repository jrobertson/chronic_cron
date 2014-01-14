Gem::Specification.new do |s|
  s.name = 'chronic_cron'
  s.version = '0.2.30'
  s.summary = 'chronic_cron'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb'] 
  s.add_dependency('app-routes')
  s.add_dependency('cron_format')
  s.add_dependency('chronic')
  s.add_dependency('timetoday')
  s.signing_key = '../privatekeys/chronic_cron.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/chronic_cron'
end
