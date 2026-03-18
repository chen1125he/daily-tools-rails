module AliyunAi
  class << self
    def base_url
      'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions'
    end

    def authorization
      "Bearer #{Rails.application.credentials.aliyun[:ai_api_key]}"
    end

    def chat(prompt:, model:)
      payload = {
        model: model,
        messages: [
          { role: :user, content: prompt }
        ]
      }
      response = Faraday.post(base_url) do |req|
        req.headers['Authorization'] = authorization
        req.headers['Content-Type'] = 'application/json'

        req.body = payload.to_json
      end

      JSON.parse(response.body)
    rescue JSON::ParserError
      raise "Failed to parse response: #{response.body}"
    end
  end
end