# frozen_string_literal: true

module Legion
  module Extensions
    module Counterfactual
      module Helpers
        module Constants
          MAX_SCENARIOS    = 200
          MAX_HISTORY      = 300
          MAX_ALTERNATIVES = 10

          PLAUSIBILITY_THRESHOLD = 0.4
          RELEVANCE_THRESHOLD    = 0.3

          DEFAULT_REGRET  = 0.0
          REGRET_DECAY    = 0.02
          REGRET_CEILING  = 1.0
          REGRET_FLOOR    = 0.0

          UPWARD_WEIGHT   = 0.7
          DOWNWARD_WEIGHT = 0.3

          COUNTERFACTUAL_TYPES = %i[upward downward additive subtractive semifactual prefactual].freeze
          MUTATION_TYPES       = %i[action inaction antecedent outcome context agent].freeze

          EMOTIONAL_RESPONSES = {
            upward:      :regret,
            downward:    :relief,
            semifactual: :acceptance,
            prefactual:  :anxiety
          }.freeze
        end
      end
    end
  end
end
