require(File.expand_path(File.join(File.dirname(__FILE__), 'core')))

module Fog
  module HP
    extend Fog::Provider
    
    service(:compute, 'hp/compute')
    #service(:storage, 'hp/storage')

    def self.authenticate(options)
      hp_auth_uri = options[:hp_auth_uri] || "http://agpa-ge1.csbu.hpl.hp.com/auth/v1.0"
      endpoint = URI.parse(hp_auth_uri)
      @scheme = endpoint.scheme || "http"
      @host = endpoint.host || "agpa-ge1.csbu.hpl.hp.com"
      @port = endpoint.port.to_s || "80"
      if (endpoint.path)
        @auth_path = endpoint.path.slice(1, endpoint.path.length)  # remove the leading slash
      else
        @auth_path = "auth/v1.0"
      end
      service_url = "#{@scheme}://#{@host}:#{@port}"
      connection = Fog::Connection.new(service_url)
      @hp_account_id = options[:hp_account_id]
      @hp_secret_key  = options[:hp_secret_key]
      response = connection.request({
        :expects  => [200, 204],
        :headers  => {
          'X-Auth-Key'  => @hp_secret_key,
          'X-Auth-User' => @hp_account_id
        },
        :host     => @host,
        :port     => @port,
        :method   => 'GET',
        :path     => @auth_path
      })
      response.headers.reject do |key, value|
        !['X-Server-Management-Url', 'X-Storage-Url', 'X-CDN-Management-Url', 'X-Auth-Token'].include?(key)
      end
    end

    class Mock
      def self.etag
        Fog::Mock.random_hex(32)
      end

    end
    
  end
end

