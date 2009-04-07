require 'net/http'
require 'uri'

class Akismet
  USER_AGENT = "Akismet-rb/1.0 | Akismet/1.11"

  def initialize(key, url)
    @key = key
    @url = url
  end

  def verify_key
    response = Net::HTTP.start('rest.akismet.com', 80) do |http|
      http.post('/1.1/verify-key', post_data(:key => @key, :blog => @url), {'User-Agent' => USER_AGENT})
    end

    case response.body
    when "invalid"
      raise Akismet::VerifyException, response.to_hash["x-akismet-debug-help"], caller
    when "valid"
      true
    end
  end
  
  def submit_spam(args)
    call_akismet('submit-spam', args)
  end
  
  def submit_ham(args)
    call_akismet('submit-ham', args)
  end
  
  def spam?(args)
    call_akismet('comment-check', args)
  end
  
  def ham?(args)
    !spam?(args)
  end

  def call_akismet(method, args)
    args.update(:blog => @url)

    response = Net::HTTP.start("#{@key}.rest.akismet.com", 80) do |http|
      http.post("/1.1/#{method}", post_data(args), {'User-Agent' => USER_AGENT})
    end
    
    case response.body
    when "true"
      true
    when "false"
      false
    end
  end
  
  def post_data(hash)
    hash.inject([]) do |memo, hash|
      k, v = hash
      memo << "#{k}=#{URI.escape(v)}"
    end.join('&')
  end

  class VerifyException < Exception; end
end