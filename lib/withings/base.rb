module Withings
  SCALE = 1
  BLOOD_PRESSURE_MONITOR = 4
end

# Copied over from ActiveSupport
unless Hash.new.respond_to?(:stringify_keys)
  class Hash
    def stringify_keys
      inject({}) do |options, (key, value)|
        options[key.to_s] = value
        options
      end
    end
  end
end