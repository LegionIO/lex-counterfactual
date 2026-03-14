# frozen_string_literal: true

RSpec.describe Legion::Extensions::Counterfactual::Helpers::Constants do
  subject(:klass) do
    Class.new { include Legion::Extensions::Counterfactual::Helpers::Constants }
  end

  it 'defines MAX_SCENARIOS' do
    expect(klass::MAX_SCENARIOS).to eq(200)
  end

  it 'defines MAX_HISTORY' do
    expect(klass::MAX_HISTORY).to eq(300)
  end

  it 'defines MAX_ALTERNATIVES' do
    expect(klass::MAX_ALTERNATIVES).to eq(10)
  end

  it 'defines PLAUSIBILITY_THRESHOLD' do
    expect(klass::PLAUSIBILITY_THRESHOLD).to eq(0.4)
  end

  it 'defines RELEVANCE_THRESHOLD' do
    expect(klass::RELEVANCE_THRESHOLD).to eq(0.3)
  end

  it 'defines REGRET_DECAY' do
    expect(klass::REGRET_DECAY).to eq(0.02)
  end

  it 'defines UPWARD_WEIGHT as 0.7' do
    expect(klass::UPWARD_WEIGHT).to eq(0.7)
  end

  it 'defines DOWNWARD_WEIGHT as 0.3' do
    expect(klass::DOWNWARD_WEIGHT).to eq(0.3)
  end

  it 'defines all COUNTERFACTUAL_TYPES' do
    expect(klass::COUNTERFACTUAL_TYPES).to include(:upward, :downward, :additive, :subtractive, :semifactual,
                                                   :prefactual)
  end

  it 'defines all MUTATION_TYPES' do
    expect(klass::MUTATION_TYPES).to include(:action, :inaction, :antecedent, :outcome, :context, :agent)
  end

  it 'defines EMOTIONAL_RESPONSES mapping' do
    expect(klass::EMOTIONAL_RESPONSES[:upward]).to eq(:regret)
    expect(klass::EMOTIONAL_RESPONSES[:downward]).to eq(:relief)
    expect(klass::EMOTIONAL_RESPONSES[:semifactual]).to eq(:acceptance)
    expect(klass::EMOTIONAL_RESPONSES[:prefactual]).to eq(:anxiety)
  end
end
