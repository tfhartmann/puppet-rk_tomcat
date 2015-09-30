require 'deep_merge'

module Puppet::Parser::Functions
  newfunction(:merge_hashes, :type => :rvalue, :doc => "Performs a deep merge on multiple hashes passed in as arguments.") do |args|
    begin
      merged = {}

      args.each do |arg|
        merged.deep_merge!(arg, { :merge_hash_arrays => true })
      end

      merged

    rescue StandardError => e
      raise Puppet::ParseError, e.message
    end
  end
end
