# frozen_string_literal: true

module Legion
  module Extensions
    module Counterfactual
      class Client
        include Runners::Counterfactual

        def initialize(**opts)
          @engine = opts[:engine] if opts[:engine]
        end
      end
    end
  end
end
