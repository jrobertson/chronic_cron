Gem::Specification.new do |s|
  s.name = 'chronic_cron'
  s.version = '0.2.5'
  s.summary = 'chronic_cron'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb'] 
  s.add_dependency('app-routes')
  s.add_dependency('cron_format')
  s.add_dependency('chronic')
  s.signing_key = '../privatekeys/chronic_cron.pem'
  s.cert_chain  = ['gem-public_cert.pem']
end
