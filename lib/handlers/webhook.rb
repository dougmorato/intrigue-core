module Intrigue
module Handler
  class Webhook < Intrigue::Handler::Base

    def self.type
      "webhook"
    end

    def process(result)
      uri = "http://intrigue.io/webhook"
      begin
        recoded_string = result.export_json.encode('UTF-8', :invalid => :replace, :replace => '?')
        RestClient.post uri, recoded_string, :content_type => "application/json"
      rescue Encoding::UndefinedConversionError
        return false
      rescue JSON::GeneratorError
        return false
      end
    end

  end
end
end