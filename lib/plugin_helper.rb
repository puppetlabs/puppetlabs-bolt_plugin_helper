# The RubyPluginHelper module provides utility methods for processing and applying
# mappings to data structures, specifically for use with Puppet inventory data.
# It includes methods for extracting required data lookups from templates and
# applying these mappings to generate inventory records.
#
# @module RubyPluginHelper
module RubyPluginHelper
  # 'template' is the value of `target_mapping` from the inventory
  # Returns an array of strings which are the lookups from the template
  def required_data(template)
    lookups = []
    postwalk_vals(template) do |value|
      # First collect the lookups to make
      lookups << value if value.is_a?(String)
      value
    end
    lookups.uniq.map { |lookup| lookup.split('.') }
  end

  # 'template' is the value of `target_mapping` from the inventory
  # 'lookup' is a hash of lookups to their resolved values for a single record
  # Returns an array of hashes to be sent to the inventory
  def apply_mapping(template, lookup, accept_nil = false)
    postwalk_vals(template) do |value|
      if value.is_a?(String)
        segments = value.split('.').map do |segment|
          # Turn it into an integer if we can
          Integer(segment)
        rescue ArgumentError
          # Otherwise return the value
          segment
        end
        answer = lookup.dig(*segments)
        if answer.nil? && !accept_nil
          msg = "Could not resolve lookup for #{value}"
          raise StandardError, msg
        end
        answer
      elsif value.is_a?(Array) || value.is_a?(Hash)
        value
      else
        msg = 'target_mapping values must be a string, array, or hash. ' \
          "Got #{value.class}"
        raise StandardError, msg
      end
    end
  end

  # Accepts a Data object and returns a copy with all hash and array values
  # modified by the given block. Descendants are modified before their
  # parents.
  def postwalk_vals(data, skip_top = false, &block)
    new_data = if data.is_a? Hash
                 data.each_with_object({}) do |(k, v), acc|
                   acc[k] = postwalk_vals(v, &block)
                 end
               elsif data.is_a? Array
                 data.map { |v| postwalk_vals(v, &block) }
               else
                 data
               end
    if skip_top
      new_data
    else
      yield(new_data)
    end
  end
end
