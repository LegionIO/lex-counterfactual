# frozen_string_literal: true

require_relative 'lib/legion/extensions/counterfactual/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-counterfactual'
  spec.version       = Legion::Extensions::Counterfactual::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LegionIO counterfactual thinking extension'
  spec.description   = 'Counterfactual reasoning for LegionIO — imagining alternative outcomes, ' \
                       'computing regret/relief, and extracting lessons from what-if scenarios'
  spec.homepage      = 'https://github.com/LegionIO/lex-counterfactual'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['changelog_uri']         = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']
end
