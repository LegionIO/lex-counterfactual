# frozen_string_literal: true

require_relative 'counterfactual/version'
require_relative 'counterfactual/helpers/constants'
require_relative 'counterfactual/helpers/scenario'
require_relative 'counterfactual/helpers/counterfactual_engine'
require_relative 'counterfactual/runners/counterfactual'
require_relative 'counterfactual/client'

module Legion
  module Extensions
    module Counterfactual
      extend Legion::Extensions::Core if defined?(Legion::Extensions::Core)
    end
  end
end
