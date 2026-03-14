# frozen_string_literal: true

RSpec.describe Legion::Extensions::Counterfactual::Helpers::Scenario do
  let(:base_params) do
    {
      scenario_type:          :upward,
      mutation_type:          :action,
      actual_outcome:         'project failed',
      counterfactual_outcome: 'project succeeded',
      antecedent:             'had reviewed code',
      domain:                 :engineering,
      plausibility:           0.8,
      regret_magnitude:       0.6
    }
  end

  subject(:scenario) { described_class.new(**base_params) }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(scenario.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'assigns scenario_type' do
      expect(scenario.scenario_type).to eq(:upward)
    end

    it 'assigns mutation_type' do
      expect(scenario.mutation_type).to eq(:action)
    end

    it 'assigns actual_outcome' do
      expect(scenario.actual_outcome).to eq('project failed')
    end

    it 'assigns counterfactual_outcome' do
      expect(scenario.counterfactual_outcome).to eq('project succeeded')
    end

    it 'assigns antecedent' do
      expect(scenario.antecedent).to eq('had reviewed code')
    end

    it 'assigns domain' do
      expect(scenario.domain).to eq(:engineering)
    end

    it 'clamps plausibility to [0, 1]' do
      s = described_class.new(**base_params, plausibility: 1.5)
      expect(s.plausibility).to eq(1.0)
    end

    it 'clamps regret_magnitude to [0, 1]' do
      s = described_class.new(**base_params, regret_magnitude: -0.5)
      expect(s.regret_magnitude).to eq(0.0)
    end

    it 'starts unresolved' do
      expect(scenario.resolved).to be false
    end

    it 'sets created_at' do
      expect(scenario.created_at).to be_a(Time)
    end

    it 'has nil lesson initially' do
      expect(scenario.lesson).to be_nil
    end

    it 'has nil resolved_at initially' do
      expect(scenario.resolved_at).to be_nil
    end
  end

  describe '#upward?' do
    it 'returns true for upward type' do
      expect(scenario.upward?).to be true
    end

    it 'returns false for non-upward type' do
      s = described_class.new(**base_params, scenario_type: :downward)
      expect(s.upward?).to be false
    end
  end

  describe '#downward?' do
    it 'returns true for downward type' do
      s = described_class.new(**base_params, scenario_type: :downward)
      expect(s.downward?).to be true
    end

    it 'returns false for upward type' do
      expect(scenario.downward?).to be false
    end
  end

  describe '#prefactual?' do
    it 'returns true for prefactual type' do
      s = described_class.new(**base_params, scenario_type: :prefactual)
      expect(s.prefactual?).to be true
    end

    it 'returns false for upward type' do
      expect(scenario.prefactual?).to be false
    end
  end

  describe '#emotional_response' do
    it 'returns :regret for upward' do
      expect(scenario.emotional_response).to eq(:regret)
    end

    it 'returns :relief for downward' do
      s = described_class.new(**base_params, scenario_type: :downward)
      expect(s.emotional_response).to eq(:relief)
    end

    it 'returns :acceptance for semifactual' do
      s = described_class.new(**base_params, scenario_type: :semifactual)
      expect(s.emotional_response).to eq(:acceptance)
    end

    it 'returns :anxiety for prefactual' do
      s = described_class.new(**base_params, scenario_type: :prefactual)
      expect(s.emotional_response).to eq(:anxiety)
    end

    it 'returns :neutral for unmapped types' do
      s = described_class.new(**base_params, scenario_type: :additive)
      expect(s.emotional_response).to eq(:neutral)
    end
  end

  describe '#emotional_valence' do
    it 'is negative for upward (regret)' do
      expect(scenario.emotional_valence).to be < 0
    end

    it 'is positive for downward (relief)' do
      s = described_class.new(**base_params, scenario_type: :downward)
      expect(s.emotional_valence).to be > 0
    end

    it 'is -0.2 for prefactual' do
      s = described_class.new(**base_params, scenario_type: :prefactual)
      expect(s.emotional_valence).to eq(-0.2)
    end

    it 'is 0.0 for additive (unmapped)' do
      s = described_class.new(**base_params, scenario_type: :additive)
      expect(s.emotional_valence).to eq(0.0)
    end
  end

  describe '#resolve' do
    it 'marks scenario as resolved' do
      scenario.resolve(lesson: 'always review code')
      expect(scenario.resolved).to be true
    end

    it 'sets the lesson' do
      scenario.resolve(lesson: 'always review code')
      expect(scenario.lesson).to eq('always review code')
    end

    it 'sets resolved_at' do
      scenario.resolve(lesson: 'lesson')
      expect(scenario.resolved_at).to be_a(Time)
    end

    it 'returns self' do
      result = scenario.resolve(lesson: 'lesson')
      expect(result).to eq(scenario)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all key fields' do
      h = scenario.to_h
      expect(h[:id]).to eq(scenario.id)
      expect(h[:scenario_type]).to eq(:upward)
      expect(h[:mutation_type]).to eq(:action)
      expect(h[:actual_outcome]).to eq('project failed')
      expect(h[:counterfactual_outcome]).to eq('project succeeded')
      expect(h[:antecedent]).to eq('had reviewed code')
      expect(h[:domain]).to eq(:engineering)
      expect(h[:plausibility]).to eq(0.8)
      expect(h[:regret_magnitude]).to eq(0.6)
      expect(h[:emotional_response]).to eq(:regret)
      expect(h[:resolved]).to be false
    end
  end
end
