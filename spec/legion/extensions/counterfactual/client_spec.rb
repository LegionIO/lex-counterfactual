# frozen_string_literal: true

RSpec.describe Legion::Extensions::Counterfactual::Client do
  subject(:client) { described_class.new }

  it 'responds to imagine_counterfactual' do
    expect(client).to respond_to(:imagine_counterfactual)
  end

  it 'responds to generate_alternatives' do
    expect(client).to respond_to(:generate_alternatives)
  end

  it 'responds to resolve_counterfactual' do
    expect(client).to respond_to(:resolve_counterfactual)
  end

  it 'responds to compute_regret' do
    expect(client).to respond_to(:compute_regret)
  end

  it 'responds to net_regret_level' do
    expect(client).to respond_to(:net_regret_level)
  end

  it 'responds to domain_regret' do
    expect(client).to respond_to(:domain_regret)
  end

  it 'responds to lessons_learned' do
    expect(client).to respond_to(:lessons_learned)
  end

  it 'responds to update_counterfactual' do
    expect(client).to respond_to(:update_counterfactual)
  end

  it 'responds to counterfactual_stats' do
    expect(client).to respond_to(:counterfactual_stats)
  end

  it 'accepts an injected engine' do
    fake_engine = Legion::Extensions::Counterfactual::Helpers::CounterfactualEngine.new
    client_with_engine = described_class.new(engine: fake_engine)
    result = client_with_engine.counterfactual_stats
    expect(result[:success]).to be true
  end
end
