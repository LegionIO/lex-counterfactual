# frozen_string_literal: true

RSpec.describe Legion::Extensions::Counterfactual::Helpers::CounterfactualEngine do
  subject(:engine) { described_class.new }

  let(:base_generate_params) do
    {
      actual_outcome:         'task failed',
      counterfactual_outcome: 'task succeeded',
      antecedent:             'had more time',
      scenario_type:          :upward,
      mutation_type:          :action,
      domain:                 :work,
      plausibility:           0.75,
      regret_magnitude:       0.6
    }
  end

  describe '#initialize' do
    it 'starts with empty scenarios' do
      expect(engine.scenarios).to be_empty
    end
  end

  describe '#generate' do
    it 'returns a Scenario instance' do
      result = engine.generate(**base_generate_params)
      expect(result).to be_a(Legion::Extensions::Counterfactual::Helpers::Scenario)
    end

    it 'stores the scenario' do
      scenario = engine.generate(**base_generate_params)
      expect(engine.scenarios[scenario.id]).to eq(scenario)
    end

    it 'increments scenario count' do
      engine.generate(**base_generate_params)
      engine.generate(**base_generate_params, scenario_type: :downward)
      expect(engine.scenarios.size).to eq(2)
    end
  end

  describe '#generate_alternatives' do
    it 'returns an array of scenarios' do
      result = engine.generate_alternatives(actual_outcome: 'outcome', domain: :testing)
      expect(result).to all(be_a(Legion::Extensions::Counterfactual::Helpers::Scenario))
    end

    it 'stores all generated alternatives' do
      result = engine.generate_alternatives(actual_outcome: 'outcome', domain: :testing)
      result.each { |s| expect(engine.scenarios[s.id]).to eq(s) }
    end

    it 'generates both upward and downward types' do
      result = engine.generate_alternatives(actual_outcome: 'outcome', domain: :testing)
      types = result.map(&:scenario_type).uniq
      expect(types).to include(:upward, :downward)
    end

    it 'uses the provided domain' do
      result = engine.generate_alternatives(actual_outcome: 'outcome', domain: :ops)
      expect(result.all? { |s| s.domain == :ops }).to be true
    end
  end

  describe '#resolve' do
    it 'resolves an existing scenario with a lesson' do
      scenario = engine.generate(**base_generate_params)
      result = engine.resolve(scenario_id: scenario.id, lesson: 'plan ahead')
      expect(result.resolved).to be true
      expect(result.lesson).to eq('plan ahead')
    end

    it 'returns nil for unknown scenario_id' do
      result = engine.resolve(scenario_id: 'nonexistent', lesson: 'lesson')
      expect(result).to be_nil
    end
  end

  describe '#compute_regret' do
    it 'computes positive regret for upward scenario' do
      scenario = engine.generate(**base_generate_params, scenario_type: :upward)
      regret = engine.compute_regret(scenario_id: scenario.id)
      expect(regret).to be > 0
    end

    it 'computes negative regret (relief) for downward scenario' do
      scenario = engine.generate(**base_generate_params, scenario_type: :downward)
      regret = engine.compute_regret(scenario_id: scenario.id)
      expect(regret).to be < 0
    end

    it 'returns 0.0 for unknown scenario' do
      expect(engine.compute_regret(scenario_id: 'missing')).to eq(0.0)
    end

    it 'returns 0.0 for non-upward/downward types' do
      scenario = engine.generate(**base_generate_params, scenario_type: :semifactual)
      expect(engine.compute_regret(scenario_id: scenario.id)).to eq(0.0)
    end

    it 'upward regret uses UPWARD_WEIGHT * magnitude * plausibility' do
      scenario = engine.generate(**base_generate_params, scenario_type:    :upward,
                                                         regret_magnitude: 0.5,
                                                         plausibility:     1.0)
      expected = 0.5 * 0.7 * 1.0
      expect(engine.compute_regret(scenario_id: scenario.id)).to be_within(0.001).of(expected)
    end
  end

  describe '#net_regret' do
    it 'sums regret across all unresolved scenarios' do
      engine.generate(**base_generate_params, scenario_type: :upward)
      engine.generate(**base_generate_params, scenario_type: :downward)
      net = engine.net_regret
      expect(net).to be_a(Float)
    end

    it 'returns 0.0 when there are no scenarios' do
      expect(engine.net_regret).to eq(0.0)
    end

    it 'excludes resolved scenarios' do
      scenario = engine.generate(**base_generate_params, scenario_type: :upward)
      engine.resolve(scenario_id: scenario.id, lesson: 'learned')
      expect(engine.net_regret).to eq(0.0)
    end
  end

  describe '#domain_regret' do
    it 'returns regret only for matching domain' do
      engine.generate(**base_generate_params, domain: :work)
      engine.generate(**base_generate_params, domain: :personal, scenario_type: :downward)
      work_regret = engine.domain_regret(domain: :work)
      expect(work_regret).to be_a(Float)
    end

    it 'returns 0.0 for domain with no scenarios' do
      expect(engine.domain_regret(domain: :unknown)).to eq(0.0)
    end
  end

  describe '#lessons_learned' do
    it 'returns only resolved scenarios with lessons' do
      s1 = engine.generate(**base_generate_params)
      engine.generate(**base_generate_params, scenario_type: :downward)
      engine.resolve(scenario_id: s1.id, lesson: 'be more careful')
      lessons = engine.lessons_learned
      expect(lessons.size).to eq(1)
      expect(lessons.first.lesson).to eq('be more careful')
    end

    it 'returns empty array when no lessons' do
      engine.generate(**base_generate_params)
      expect(engine.lessons_learned).to be_empty
    end
  end

  describe '#regret_decay' do
    it 'reduces regret_magnitude on unresolved scenarios' do
      scenario = engine.generate(**base_generate_params, regret_magnitude: 0.5)
      engine.regret_decay
      expect(scenario.regret_magnitude).to be < 0.5
    end

    it 'does not decay below REGRET_FLOOR' do
      scenario = engine.generate(**base_generate_params, regret_magnitude: 0.0)
      engine.regret_decay
      expect(scenario.regret_magnitude).to eq(0.0)
    end

    it 'does not decay resolved scenarios' do
      scenario = engine.generate(**base_generate_params, regret_magnitude: 0.5)
      engine.resolve(scenario_id: scenario.id, lesson: 'learned')
      engine.regret_decay
      expect(scenario.regret_magnitude).to eq(0.5)
    end
  end

  describe '#by_type' do
    it 'returns scenarios matching type' do
      engine.generate(**base_generate_params, scenario_type: :upward)
      engine.generate(**base_generate_params, scenario_type: :downward)
      upward = engine.by_type(type: :upward)
      expect(upward.all? { |s| s.scenario_type == :upward }).to be true
      expect(upward.size).to eq(1)
    end
  end

  describe '#by_domain' do
    it 'returns scenarios matching domain' do
      engine.generate(**base_generate_params, domain: :work)
      engine.generate(**base_generate_params, domain: :home)
      work = engine.by_domain(domain: :work)
      expect(work.size).to eq(1)
      expect(work.first.domain).to eq(:work)
    end
  end

  describe '#unresolved' do
    it 'returns only unresolved scenarios' do
      s1 = engine.generate(**base_generate_params)
      engine.generate(**base_generate_params, scenario_type: :downward)
      engine.resolve(scenario_id: s1.id, lesson: 'lesson')
      expect(engine.unresolved.size).to eq(1)
    end
  end

  describe '#recent' do
    it 'returns last n scenarios by created_at' do
      3.times { engine.generate(**base_generate_params) }
      result = engine.recent(count: 2)
      expect(result.size).to eq(2)
    end

    it 'returns all when count > total' do
      engine.generate(**base_generate_params)
      result = engine.recent(count: 10)
      expect(result.size).to eq(1)
    end
  end

  describe '#to_h' do
    it 'returns a stats summary hash' do
      engine.generate(**base_generate_params)
      h = engine.to_h
      expect(h[:total]).to eq(1)
      expect(h[:unresolved]).to eq(1)
      expect(h[:resolved]).to eq(0)
      expect(h[:net_regret]).to be_a(Float)
      expect(h[:by_type]).to be_a(Hash)
    end
  end
end
