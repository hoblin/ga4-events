# frozen_string_literal: true

# https://support.google.com/analytics/answer/9267744
class GA4::Events::Event
  attr_reader :name, :params

  MAX_EVENT_NAME_LENGTH = 40
  MAX_PARAMS_COUNT = 25
  MAX_PARAM_NAME_LENGTH = 40
  MAX_PARAM_VALUE_LENGTH = 100

  def initialize(name, params = {})
    @name = name.to_s
    @params = params
  end

  def valid?
    errors.empty?
  end

  def errors
    # ? do we really need memoization here?
    @errors ||= validate_event
  end

  def to_h(debug_mode: false)
    {
      name: name,
      params: processed_params(debug_mode)
    }
  end

  private

  def processed_params(debug_mode)
    return params unless debug_mode

    # Inject debug_mode param if requested
    (params || {}).dup.tap do |event_params|
      event_params["debug_mode"] = "1"
    end
  end

  def validate_event
    errors = []

    # Validate event name
    if name.nil? || name.empty?
      errors << "Event name cannot be empty"
    elsif name.length > MAX_EVENT_NAME_LENGTH
      errors << "Event name cannot exceed #{MAX_EVENT_NAME_LENGTH} characters"
    end

    # Validate params
    if params.is_a?(Hash)
      if params.size > MAX_PARAMS_COUNT
        errors << "Event cannot have more than #{MAX_PARAMS_COUNT} parameters"
      end

      params.each do |key, value|
        param_name = key.to_s

        if param_name.length > MAX_PARAM_NAME_LENGTH
          errors << "Parameter name '#{param_name}' exceeds #{MAX_PARAM_NAME_LENGTH} characters"
        end

        if value.is_a?(String) && value.length > MAX_PARAM_VALUE_LENGTH
          errors << "Parameter '#{param_name}' value exceeds #{MAX_PARAM_VALUE_LENGTH} characters"
        end
      end
    elsif !params.nil?
      errors << "Event params must be a Hash"
    end

    errors
  end
end
