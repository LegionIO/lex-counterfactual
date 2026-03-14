# lex-counterfactual

Counterfactual reasoning extension for the LegionIO brain-modeled cognitive architecture.

## What It Does

Models the mental process of imagining alternative outcomes to past events — what-if thinking. The agent can generate scenarios asking "what if I had done X instead?", compute regret or relief from those scenarios, resolve them by extracting lessons, and track net regret across domains.

Two primary counterfactual directions:
- **Upward counterfactuals**: imagining better outcomes → produces regret
- **Downward counterfactuals**: imagining worse outcomes → produces relief

Additional types: additive, subtractive, semifactual, prefactual.

## Usage

```ruby
client = Legion::Extensions::Counterfactual::Client.new

# Imagine a specific counterfactual
result = client.imagine_counterfactual(
  actual_outcome:         :deployment_failed,
  counterfactual_outcome: :deployment_succeeded,
  antecedent:             'if tests had run before merge',
  scenario_type:          :upward,
  mutation_type:          :action,
  domain:                 :engineering,
  plausibility:           0.8
)
# => { success: true, scenario: { id:, scenario_type: :upward, regret_magnitude: 0.5, ... } }

# Generate multiple alternatives automatically
result = client.generate_alternatives(actual_outcome: :missed_deadline, domain: :planning)
# => { success: true, alternatives: [...], count: 6 }

# Compute regret for a specific scenario
client.compute_regret(scenario_id: result.dig(:scenario, :id))
# => { success: true, regret: 0.2803 }

# Resolve with a lesson
client.resolve_counterfactual(scenario_id: id, lesson: 'Always run integration tests before merge')

# Get all lessons extracted from resolved scenarios
client.lessons_learned
# => { success: true, lessons: [...], count: 3 }

# Apply regret decay (call on tick)
client.update_counterfactual

# Get overall stats
client.counterfactual_stats
# => { success: true, stats: { total:, unresolved:, net_regret:, ... } }
```

## Key Concepts

**Scenario types**: `:upward` (better), `:downward` (worse), `:additive` (add an action), `:subtractive` (remove an action), `:semifactual` (same outcome despite change), `:prefactual` (anticipatory).

**Mutation types**: `:action`, `:inaction`, `:antecedent`, `:outcome`, `:context`, `:agent`.

**Regret** is weighted: upward counterfactuals carry 0.7x weight, downward 0.3x. Net regret accumulates until resolved or decayed.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
