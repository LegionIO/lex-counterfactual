# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Counterfactual
      module Helpers
        class CounterfactualEngine
          include Constants

          attr_reader :scenarios

          def initialize
            @scenarios = {}
          end

          # rubocop:disable Metrics/ParameterLists
          def generate(actual_outcome:, counterfactual_outcome:, antecedent:,
                       scenario_type:, mutation_type:, domain:, plausibility:,
                       regret_magnitude: 0.5)
            prune_if_needed
            scenario = Scenario.new(
              scenario_type:          scenario_type,
              mutation_type:          mutation_type,
              actual_outcome:         actual_outcome,
              counterfactual_outcome: counterfactual_outcome,
              antecedent:             antecedent,
              domain:                 domain,
              plausibility:           plausibility,
              regret_magnitude:       regret_magnitude
            )
            @scenarios[scenario.id] = scenario
            scenario
          end
          # rubocop:enable Metrics/ParameterLists

          def generate_alternatives(actual_outcome:, domain:)
            alternatives = []
            mutation_samples = MUTATION_TYPES.first(MAX_ALTERNATIVES)

            mutation_samples.each_with_index do |mutation, idx|
              type = idx.even? ? :upward : :downward
              plausibility = (0.8 - (idx * 0.1)).clamp(PLAUSIBILITY_THRESHOLD, 1.0)

              scenario = generate(
                actual_outcome:         actual_outcome,
                counterfactual_outcome: "alternative_#{mutation}_#{idx}",
                antecedent:             "#{mutation}_variation_#{idx}",
                scenario_type:          type,
                mutation_type:          mutation,
                domain:                 domain,
                plausibility:           plausibility,
                regret_magnitude:       0.5
              )
              alternatives << scenario
            end

            alternatives
          end

          def resolve(scenario_id:, lesson:)
            scenario = @scenarios[scenario_id]
            return nil unless scenario

            scenario.resolve(lesson: lesson)
            scenario
          end

          def compute_regret(scenario_id:)
            scenario = @scenarios[scenario_id]
            return 0.0 unless scenario

            if scenario.upward?
              scenario.regret_magnitude * UPWARD_WEIGHT * scenario.plausibility
            elsif scenario.downward?
              -(scenario.regret_magnitude * DOWNWARD_WEIGHT * scenario.plausibility)
            else
              0.0
            end
          end

          def net_regret
            unresolved.sum(0.0) { |s| compute_regret(scenario_id: s.id) }
          end

          def domain_regret(domain:)
            by_domain(domain: domain).reject(&:resolved).sum(0.0) { |s| compute_regret(scenario_id: s.id) }
          end

          def lessons_learned
            @scenarios.values.select { |s| s.resolved && s.lesson }
          end

          def regret_decay
            unresolved.each do |scenario|
              new_magnitude = (scenario.regret_magnitude - REGRET_DECAY).clamp(REGRET_FLOOR, REGRET_CEILING)
              scenario.instance_variable_set(:@regret_magnitude, new_magnitude)
              scenario.instance_variable_set(:@emotional_valence, recompute_valence(scenario))
            end
          end

          def by_type(type:)
            @scenarios.values.select { |s| s.scenario_type == type }
          end

          def by_domain(domain:)
            @scenarios.values.select { |s| s.domain == domain }
          end

          def unresolved
            @scenarios.values.reject(&:resolved)
          end

          def recent(count:)
            @scenarios.values.sort_by(&:created_at).last(count)
          end

          def to_h
            {
              total:         @scenarios.size,
              unresolved:    unresolved.size,
              resolved:      lessons_learned.size,
              net_regret:    net_regret.round(4),
              by_type:       type_summary,
              lessons_count: lessons_learned.size
            }
          end

          private

          def prune_if_needed
            return unless @scenarios.size >= MAX_SCENARIOS

            oldest = @scenarios.values.min_by(&:created_at)
            @scenarios.delete(oldest.id) if oldest
          end

          def type_summary
            COUNTERFACTUAL_TYPES.to_h { |type| [type, @scenarios.values.count { |s| s.scenario_type == type }] }
          end

          def recompute_valence(scenario)
            case scenario.scenario_type
            when :upward     then -(scenario.regret_magnitude * UPWARD_WEIGHT)
            when :downward   then scenario.regret_magnitude * DOWNWARD_WEIGHT
            when :prefactual then -0.2
            else 0.0
            end
          end
        end
      end
    end
  end
end
