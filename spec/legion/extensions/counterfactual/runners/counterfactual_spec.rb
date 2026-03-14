# frozen_string_literal: true

RSpec.describe Legion::Extensions::Counterfactual::Runners::Counterfactual do
  let(:client) { Legion::Extensions::Counterfactual::Client.new }

  let(:valid_imagine_params) do
    {
      actual_outcome:         'deployment failed',
      counterfactual_outcome: 'deployment succeeded',
      antecedent:             'had run staging first',
      scenario_type:          :upward,
      mutation_type:          :action,
      domain:                 :ops,
      plausibility:           0.8
    }
  end

  describe '#imagine_counterfactual' do
    it 'returns success: true with a scenario hash' do
      result = client.imagine_counterfactual(**valid_imagine_params)
      expect(result[:success]).to be true
      expect(result[:scenario]).to be_a(Hash)
    end

    it 'scenario hash includes expected keys' do
      result = client.imagine_counterfactual(**valid_imagine_params)
      s = result[:scenario]
      expect(s[:id]).not_to be_nil
      expect(s[:scenario_type]).to eq(:upward)
      expect(s[:domain]).to eq(:ops)
    end

    it 'returns success: false for invalid scenario_type' do
      result = client.imagine_counterfactual(**valid_imagine_params, scenario_type: :invalid)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_scenario_type)
    end

    it 'returns success: false for invalid mutation_type' do
      result = client.imagine_counterfactual(**valid_imagine_params, mutation_type: :bogus)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_mutation_type)
    end

    it 'accepts all valid counterfactual types' do
      Legion::Extensions::Counterfactual::Helpers::Constants::COUNTERFACTUAL_TYPES.each do |type|
        result = client.imagine_counterfactual(**valid_imagine_params, scenario_type: type)
        expect(result[:success]).to be true
      end
    end

    it 'accepts all valid mutation types' do
      Legion::Extensions::Counterfactual::Helpers::Constants::MUTATION_TYPES.each do |mutation|
        result = client.imagine_counterfactual(**valid_imagine_params, mutation_type: mutation)
        expect(result[:success]).to be true
      end
    end

    it 'ignores extra keyword arguments' do
      result = client.imagine_counterfactual(**valid_imagine_params, extra_key: 'ignored')
      expect(result[:success]).to be true
    end
  end

  describe '#generate_alternatives' do
    it 'returns success: true with alternatives array' do
      result = client.generate_alternatives(actual_outcome: 'outcome', domain: :testing)
      expect(result[:success]).to be true
      expect(result[:alternatives]).to be_an(Array)
      expect(result[:count]).to be > 0
    end

    it 'count matches alternatives length' do
      result = client.generate_alternatives(actual_outcome: 'outcome', domain: :testing)
      expect(result[:count]).to eq(result[:alternatives].size)
    end
  end

  describe '#resolve_counterfactual' do
    it 'resolves an existing scenario' do
      imagine_result = client.imagine_counterfactual(**valid_imagine_params)
      scenario_id = imagine_result[:scenario][:id]

      result = client.resolve_counterfactual(scenario_id: scenario_id, lesson: 'always use staging')
      expect(result[:success]).to be true
      expect(result[:scenario][:lesson]).to eq('always use staging')
      expect(result[:scenario][:resolved]).to be true
    end

    it 'returns success: false for unknown scenario_id' do
      result = client.resolve_counterfactual(scenario_id: 'does-not-exist', lesson: 'lesson')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#compute_regret' do
    it 'returns success: true with regret value' do
      imagine_result = client.imagine_counterfactual(**valid_imagine_params)
      scenario_id = imagine_result[:scenario][:id]

      result = client.compute_regret(scenario_id: scenario_id)
      expect(result[:success]).to be true
      expect(result[:regret]).to be_a(Float)
    end

    it 'returns 0.0 for unknown scenario' do
      result = client.compute_regret(scenario_id: 'ghost')
      expect(result[:success]).to be true
      expect(result[:regret]).to eq(0.0)
    end
  end

  describe '#net_regret_level' do
    it 'returns success: true with net_regret float' do
      result = client.net_regret_level
      expect(result[:success]).to be true
      expect(result[:net_regret]).to be_a(Float)
    end

    it 'increases after adding upward scenarios' do
      before = client.net_regret_level[:net_regret]
      client.imagine_counterfactual(**valid_imagine_params, scenario_type: :upward, plausibility: 1.0)
      after = client.net_regret_level[:net_regret]
      expect(after).to be > before
    end
  end

  describe '#domain_regret' do
    it 'returns success: true with domain-specific regret' do
      result = client.domain_regret(domain: :ops)
      expect(result[:success]).to be true
      expect(result[:domain]).to eq(:ops)
      expect(result[:regret]).to be_a(Float)
    end
  end

  describe '#lessons_learned' do
    it 'returns empty lessons array when none resolved' do
      result = client.lessons_learned
      expect(result[:success]).to be true
      expect(result[:lessons]).to be_an(Array)
      expect(result[:count]).to eq(0)
    end

    it 'returns lessons after resolving scenarios' do
      imagine_result = client.imagine_counterfactual(**valid_imagine_params)
      client.resolve_counterfactual(
        scenario_id: imagine_result[:scenario][:id],
        lesson:      'test everything'
      )
      result = client.lessons_learned
      expect(result[:count]).to eq(1)
    end
  end

  describe '#update_counterfactual' do
    it 'returns success: true with action: :regret_decay' do
      result = client.update_counterfactual
      expect(result[:success]).to be true
      expect(result[:action]).to eq(:regret_decay)
    end
  end

  describe '#counterfactual_stats' do
    it 'returns success: true with stats hash' do
      result = client.counterfactual_stats
      expect(result[:success]).to be true
      expect(result[:stats]).to be_a(Hash)
      expect(result[:stats][:total]).to be_a(Integer)
    end

    it 'tracks total after adding scenarios' do
      client.imagine_counterfactual(**valid_imagine_params)
      result = client.counterfactual_stats
      expect(result[:stats][:total]).to eq(1)
    end
  end
end
