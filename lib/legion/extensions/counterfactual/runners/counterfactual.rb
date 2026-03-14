# frozen_string_literal: true

module Legion
  module Extensions
    module Counterfactual
      module Runners
        module Counterfactual
          include Helpers::Constants
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          # rubocop:disable Metrics/ParameterLists
          def imagine_counterfactual(actual_outcome:, counterfactual_outcome:, antecedent:,
                                     scenario_type:, mutation_type:, domain:, plausibility:, **)
            unless COUNTERFACTUAL_TYPES.include?(scenario_type)
              return { success: false, error: :invalid_scenario_type,
                       valid_types: COUNTERFACTUAL_TYPES }
            end

            unless MUTATION_TYPES.include?(mutation_type)
              return { success: false, error: :invalid_mutation_type,
                       valid_types: MUTATION_TYPES }
            end

            scenario = engine.generate(
              actual_outcome:         actual_outcome,
              counterfactual_outcome: counterfactual_outcome,
              antecedent:             antecedent,
              scenario_type:          scenario_type,
              mutation_type:          mutation_type,
              domain:                 domain,
              plausibility:           plausibility
            )

            Legion::Logging.debug "[counterfactual] imagined: type=#{scenario_type} " \
                                  "domain=#{domain} id=#{scenario.id[0..7]}"

            { success: true, scenario: scenario.to_h }
          end
          # rubocop:enable Metrics/ParameterLists

          def generate_alternatives(actual_outcome:, domain:, **)
            alternatives = engine.generate_alternatives(actual_outcome: actual_outcome, domain: domain)
            Legion::Logging.debug "[counterfactual] generated #{alternatives.size} alternatives for domain=#{domain}"
            { success: true, alternatives: alternatives.map(&:to_h), count: alternatives.size }
          end

          def resolve_counterfactual(scenario_id:, lesson:, **)
            scenario = engine.resolve(scenario_id: scenario_id, lesson: lesson)
            if scenario
              Legion::Logging.info "[counterfactual] resolved: id=#{scenario_id[0..7]} lesson=#{lesson[0..40]}"
              { success: true, scenario: scenario.to_h }
            else
              Legion::Logging.debug "[counterfactual] resolve failed: id=#{scenario_id[0..7]} not found"
              { success: false, reason: :not_found }
            end
          end

          def compute_regret(scenario_id:, **)
            regret = engine.compute_regret(scenario_id: scenario_id)
            Legion::Logging.debug "[counterfactual] regret: id=#{scenario_id[0..7]} value=#{regret.round(4)}"
            { success: true, scenario_id: scenario_id, regret: regret }
          end

          def net_regret_level(**)
            net = engine.net_regret
            Legion::Logging.debug "[counterfactual] net_regret=#{net.round(4)}"
            { success: true, net_regret: net }
          end

          def domain_regret(domain:, **)
            regret = engine.domain_regret(domain: domain)
            Legion::Logging.debug "[counterfactual] domain_regret: domain=#{domain} value=#{regret.round(4)}"
            { success: true, domain: domain, regret: regret }
          end

          def lessons_learned(**)
            lessons = engine.lessons_learned
            Legion::Logging.debug "[counterfactual] lessons_learned: count=#{lessons.size}"
            { success: true, lessons: lessons.map(&:to_h), count: lessons.size }
          end

          def update_counterfactual(**)
            engine.regret_decay
            Legion::Logging.debug '[counterfactual] regret decay applied'
            { success: true, action: :regret_decay }
          end

          def counterfactual_stats(**)
            stats = engine.to_h
            Legion::Logging.debug "[counterfactual] stats: total=#{stats[:total]} unresolved=#{stats[:unresolved]}"
            { success: true, stats: stats }
          end

          private

          def engine
            @engine ||= Helpers::CounterfactualEngine.new
          end
        end
      end
    end
  end
end
