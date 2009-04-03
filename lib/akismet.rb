require 'net/http'

class Akismet
  USER_AGENT = "Akismet-rb/1.0 | Akismet/1.11"

  def initialize(key, url)
    @key = key
    @url = url
  end

  def verify_key
    response = Net::HTTP.start('rest.akismet.com', 80) do |http|
      # http.instance_eval{@socket = MethodSpy.new(@socket)}
      http.post('/1.1/verify-key',
                "key=#{@key}&blog=#{@url}",
                {'User-Agent' => USER_AGENT})
    end

    if response.body == "invalid"
      raise Akismet::VerifyException, response.to_hash["x-akismet-debug-help"], caller
    end
    true
  end

  class VerifyException < Exception
  end
end