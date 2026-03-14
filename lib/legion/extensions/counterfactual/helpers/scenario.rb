# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Counterfactual
      module Helpers
        class Scenario
          include Constants

          attr_reader :id, :scenario_type, :mutation_type,
                      :actual_outcome, :counterfactual_outcome,
                      :antecedent, :domain, :plausibility,
                      :emotional_valence, :regret_magnitude,
                      :lesson, :resolved, :created_at, :resolved_at

          # rubocop:disable Metrics/ParameterLists
          def initialize(scenario_type:, mutation_type:, actual_outcome:,
                         counterfactual_outcome:, antecedent:, domain:,
                         plausibility:, regret_magnitude: 0.5)
            # rubocop:enable Metrics/ParameterLists
            @id = SecureRandom.uuid
            @scenario_type          = scenario_type
            @mutation_type          = mutation_type
            @actual_outcome         = actual_outcome
            @counterfactual_outcome = counterfactual_outcome
            @antecedent             = antecedent
            @domain                 = domain
            @plausibility           = plausibility.to_f.clamp(0.0, 1.0)
            @regret_magnitude       = regret_magnitude.to_f.clamp(0.0, 1.0)
            @emotional_valence      = compute_emotional_valence
            @lesson                 = nil
            @resolved               = false
            @created_at             = Time.now.utc
            @resolved_at            = nil
          end

          def upward?
            @scenario_type == :upward
          end

          def downward?
            @scenario_type == :downward
          end

          def prefactual?
            @scenario_type == :prefactual
          end

          def emotional_response
            EMOTIONAL_RESPONSES.fetch(@scenario_type, :neutral)
          end

          def resolve(lesson:)
            @lesson      = lesson
            @resolved    = true
            @resolved_at = Time.now.utc
            self
          end

          def to_h
            {
              id:                     @id,
              scenario_type:          @scenario_type,
              mutation_type:          @mutation_type,
              actual_outcome:         @actual_outcome,
              counterfactual_outcome: @counterfactual_outcome,
              antecedent:             @antecedent,
              domain:                 @domain,
              plausibility:           @plausibility,
              emotional_valence:      @emotional_valence,
              regret_magnitude:       @regret_magnitude,
              emotional_response:     emotional_response,
              lesson:                 @lesson,
              resolved:               @resolved,
              created_at:             @created_at,
              resolved_at:            @resolved_at
            }
          end

          private

          def compute_emotional_valence
            case @scenario_type
            when :upward     then -(@regret_magnitude * UPWARD_WEIGHT)
            when :downward   then @regret_magnitude * DOWNWARD_WEIGHT
            when :prefactual then -0.2
            else 0.0
            end
          end
        end
      end
    end
  end
end
