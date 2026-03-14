# lex-counterfactual

**Level 3 Documentation** — Parent: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## Purpose

Counterfactual reasoning engine for the LegionIO cognitive architecture. Models the mental process of imagining alternative outcomes to past events (what-if thinking), computing regret and relief, and extracting lessons from unresolved scenarios.

Supports both upward counterfactuals (imagining better outcomes, producing regret) and downward counterfactuals (imagining worse outcomes, producing relief), plus semifactual, prefactual, and additive/subtractive mutation types.

## Gem Info

- **Gem name**: `lex-counterfactual`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::Counterfactual`
- **Location**: `extensions-agentic/lex-counterfactual/`

## File Structure

```
lib/legion/extensions/counterfactual/
  counterfactual.rb              # Top-level requires
  version.rb                     # VERSION = '0.1.0'
  client.rb                      # Client class including Runners::Counterfactual
  helpers/
    constants.rb                 # MAX_SCENARIOS, thresholds, type arrays, emotional response map
    scenario.rb                  # Scenario value object (immutable after creation)
    counterfactual_engine.rb     # In-memory engine: generate, resolve, compute_regret
  runners/
    counterfactual.rb            # Runner module: all public methods
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `MAX_SCENARIOS` | 200 | Cap on in-memory scenarios |
| `MAX_ALTERNATIVES` | 10 | Max alternatives per `generate_alternatives` call |
| `PLAUSIBILITY_THRESHOLD` | 0.4 | Minimum plausibility to register a scenario |
| `UPWARD_WEIGHT` | 0.7 | Weight on upward counterfactual regret |
| `DOWNWARD_WEIGHT` | 0.3 | Weight on downward counterfactual relief |
| `REGRET_DECAY` | 0.02 | Per-tick regret decay applied by `update_counterfactual` |
| `COUNTERFACTUAL_TYPES` | `[:upward, :downward, :additive, :subtractive, :semifactual, :prefactual]` | Valid scenario types |
| `MUTATION_TYPES` | `[:action, :inaction, :antecedent, :outcome, :context, :agent]` | Valid mutation types |
| `EMOTIONAL_RESPONSES` | hash | Maps type to emotion (upward→regret, downward→relief, etc.) |

## Runners

All methods are in `Legion::Extensions::Counterfactual::Runners::Counterfactual`.

| Method | Key Args | Returns |
|---|---|---|
| `imagine_counterfactual` | `actual_outcome:, counterfactual_outcome:, antecedent:, scenario_type:, mutation_type:, domain:, plausibility:` | `{ success:, scenario: }` |
| `generate_alternatives` | `actual_outcome:, domain:` | `{ success:, alternatives:, count: }` |
| `resolve_counterfactual` | `scenario_id:, lesson:` | `{ success:, scenario: }` |
| `compute_regret` | `scenario_id:` | `{ success:, scenario_id:, regret: }` |
| `net_regret_level` | — | `{ success:, net_regret: }` |
| `domain_regret` | `domain:` | `{ success:, domain:, regret: }` |
| `lessons_learned` | — | `{ success:, lessons:, count: }` |
| `update_counterfactual` | — | `{ success:, action: :regret_decay }` |
| `counterfactual_stats` | — | `{ success:, stats: }` |

## Helpers

### `Scenario`
Value object. Attributes: `id`, `scenario_type`, `mutation_type`, `actual_outcome`, `counterfactual_outcome`, `antecedent`, `domain`, `plausibility`, `emotional_valence`, `regret_magnitude`, `lesson`, `resolved`, `created_at`, `resolved_at`. Emotional valence is computed from type and magnitude. Mutable via `resolve(lesson:)`.

### `CounterfactualEngine`
In-memory hash of `Scenario` objects keyed by UUID. Key methods: `generate(...)`, `generate_alternatives(...)`, `resolve(scenario_id:, lesson:)`, `compute_regret(scenario_id:)`, `net_regret`, `domain_regret(domain:)`, `lessons_learned`, `regret_decay`, `by_type`, `by_domain`, `unresolved`, `recent(count:)`, `to_h`.

## Integration Points

- `update_counterfactual` maps to the lex-tick periodic update phase
- `lessons_learned` feeds into lex-memory as semantic traces
- `net_regret_level` feeds into lex-emotion as a valence modifier
- `domain_regret` can inform lex-prediction confidence adjustments

## Development Notes

- Engine is memoized as `@engine` in the runner module
- Regret is directional: upward = negative valence, downward = positive relief
- `generate_alternatives` iterates over all `MUTATION_TYPES` (capped at `MAX_ALTERNATIVES`)
- Plausibility is clamped 0.0..1.0 at construction
- Rubocop disables `Metrics/ParameterLists` on the `generate` method due to 7-arg signature
