# frozen_string_literal: true

class GA4::Events::Response
  attr_reader :status_code, :body, :errors

  def initialize(status_code, body, errors = [])
    @status_code = status_code
    @body = body
    @errors = errors
  end

  def success?
    [200, 204].include?(status_code)
  end

  def failure?
    !success?
  end

  def validation_messages
    return [] unless body.is_a?(Hash)

    body.dig("validationMessages") || []
  end

  def to_h
    {
      status_code: status_code,
      success: success?,
      body: body,
      errors: errors,
      validation_messages: validation_messages
    }
  end

  def to_s
    if success?
      "Success (#{status_code})"
    else
      error_msg = errors.join(", ")
      "Failure (#{status_code}): #{error_msg}"
    end
  end
end
