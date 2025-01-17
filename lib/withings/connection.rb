# A convenience class for making get requests to WBS API.
# It verifies the response and raises ApiError if a call failed.
class Withings::Connection
  include HTTParty
  if ENV.has_key?('http_proxy')
    uri = URI.parse(ENV['http_proxy'])
    http_proxy uri.host, uri.port
  end

  base_uri 'wbsapi.withings.net'
  format :json

  def initialize(user)
    @user = user
  end

  def self.get_request(path, token, secret, params)
    signature = Withings::Connection.sign(base_uri + path, params, token, secret)
    params.merge!({:oauth_signature => signature})
    
    response = self.get(path, :query => params)
    verify_response!(response, path, params)
  end


  def get_request(path, params)
    params.merge!({:userid => @user.user_id, :publickey => @user.public_key})
    signature = Withings::Connection.sign(self.class.base_uri + path, params, @user.oauth_token, @user.oauth_token_secret)
    params.merge!({:oauth_signature => signature})
    puts "path: #{path}"
    params.map { |e| puts "params - #{e}" }
    
    response = self.class.get(path, :query => params)
    puts response
    self.class.verify_response!(response, path, params)
  end
  
  protected
  
  def self.sign(url, params, token, secret)
    params.merge!({
      :oauth_consumer_key => Withings.consumer_key,
      :oauth_nonce => oauth_nonce,
      :oauth_signature_method => oauth_signature_method,
      :oauth_timestamp => oauth_timestamp,
      :oauth_version => oauth_version,
      :oauth_token => token
    })
    calculate_oauth_signature('GET', url, params, secret)
  end
  
  
  def self.oauth_timestamp
    Time.now.to_i
  end
  
  def self.oauth_version
    '1.0'
  end
  
  def self.oauth_signature_method
    'HMAC-SHA1'
  end
  
  def self.oauth_nonce
    rand(10 ** 30).to_s(16)
  end
  
  def self.calculate_oauth_signature(method, url, params, oauth_token_secret)
    # oauth signing is picky with sorting (based on a digest)
    params = params.to_a.map() do |item| 
      [item.first.to_s, CGI.escape(item.last.to_s)]
    end.sort
    
    param_string = params.map() {|key, value| "#{key}=#{value}"}.join('&')
    base_string = [method, CGI.escape(url), CGI.escape(param_string)].join('&')
    
    secret = [Withings.consumer_secret, oauth_token_secret].join('&')
    
    digest = HMAC::SHA1.digest(secret, base_string)
    Base64.encode64(digest).chomp.gsub( /\n/, '' )
  end
  
  
  # Verifies the status code in the JSON response and returns either the body element or raises ApiError
  def self.verify_response!(response, path, params)
    if response['status'] == 0
      response['body'] || response['status']
    else
      raise Withings::ApiError.new(response['status'], path, params)
    end
  end
end


#http://wbsapi.withings.net/measure?action=getmeas&
#oauth_consumer_key=7e563166232c6821742b4c277350494a455f392b353e5d49712a34762a&
#oauth_nonce=f22d74f2209ddf0c6558a47c02841fb1&
#oauth_signature=yAF9SgZa09SPl3H1Y5aAoXgyauc=&
#oauth_token=c68567f1760552958d713e92088db9f5c5189754dfe4e92068971f4e25d64&
#oauth_version=1.0&
#userid=1229

#User: Tobias Miesel
#user_id: 666088
#oauth_token: 284948c9b4b9cce1cc76bbb77283431d9bbb9b46beddfccb79241cc12
#oauth_token_secret: 02f01f0e60182684676644ddbef2638e8e4de909f776340e1b5dd612dcbf