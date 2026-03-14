# frozen_string_literal: true

require 'legion/extensions/counterfactual'

# Stub Legion::Logging if not loaded
unless defined?(Legion::Logging)
  module Legion
    module Logging
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def log; end
      end

      def self.debug(_msg); end

      def self.info(_msg); end

      def self.warn(_msg); end

      def self.error(_msg); end

      def log; end
    end
  end
end
