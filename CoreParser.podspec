Pod::Spec.new do |s|
   s.name = 'CoreParser'
   s.version = '1.0'
   s.license = 'MIT'

   s.summary = 'Lib CoreParser'
   s.homepage = 'https://github.com/Klimowsa/CoreParser'
   s.author = 'RMR + AGIMA'

   s.source = { :git => 'https://github.com/Klimowsa/CoreParser.git', :tag => s.version }
   s.source_files = 'Source/CoreParser/**/*.{h,m}'

   s.platform = :ios
   s.ios.deployment_target = '8.0'

   s.frameworks = 'Realm'
   s.dependency 'Realm', '~> 1.0'

   s.requires_arc = true
end