require File.expand_path(File.join(File.dirname(__FILE__), '..', 'hp'))

require 'fog/compute'

module Fog
  module HP
    class Compute < Fog::Service

      requires    :hp_secret_key, :hp_account_id
      recognizes  :hp_auth_uri, :hp_servicenet, :persistent
      recognizes  :provider # remove post deprecation

      model_path 'fog/hp/models/compute'
      model       :flavor
      collection  :flavors
      model       :image
      collection  :images
      model       :server
      collection  :servers

      request_path 'fog/hp/requests/compute'
      #request :confirm_resized_server
      request :create_image
      request :create_server
      request :delete_image
      request :delete_server
      request :get_flavor_details
      request :get_image_details
      request :get_server_details
      request :list_addresses
      request :list_private_addresses
      request :list_public_addresses
      request :list_flavors
      request :list_flavors_detail
      request :list_images
      request :list_images_detail
      request :list_servers
      request :list_servers_detail
      request :reboot_server
      #request :revert_resized_server
      #request :resize_server
      request :server_action
      request :update_server

      class Mock

        def self.data
          @data ||= Hash.new do |hash, key|
            hash[key] = {
              :last_modified => {
                :images  => {},
                :servers => {}
              },
              :images  => {},
              :servers => {}
            }
          end
        end

        def self.reset
          @data = nil
        end

        def initialize(options={})
          unless options.delete(:provider)
            location = caller.first
            warning = "[yellow][WARN] Fog::HP::Compute.new is deprecated, use Fog::Compute.new(:provider => 'HP') instead[/]"
            warning << " [light_black](" << location << ")[/] "
            Formatador.display_line(warning)
          end

          @hp_account_id = options[:hp_account_id]
        end

        def data
          self.class.data[@hp_account_id]
        end

        def reset_data
          self.class.data.delete(@hp_account_id)
        end

      end

      class Real

        def initialize(options={})
          unless options.delete(:provider)
            location = caller.first
            warning = "[yellow][WARN] Fog::HP::Compute.new is deprecated, use Fog::Compute.new(:provider => 'HP') instead[/]"
            warning << " [light_black](" << location << ")[/] "
            Formatador.display_line(warning)
          end

          require 'json'
          @hp_secret_key = options[:hp_secret_key]
          @hp_account_id = options[:hp_account_id]
          @hp_auth_uri   = options[:hp_auth_uri]
          @hp_servicenet = options[:hp_servicenet]
          authenticate
          Excon.ssl_verify_peer = false if options[:hp_servicenet] == true
          @connection = Fog::Connection.new("#{@scheme}://#{@host}:#{@port}", options[:persistent])
        end

        def reload
          @connection.reset
        end

        def request(params)
          begin
            response = @connection.request(params.merge!({
              :headers  => {
                'Content-Type' => 'application/json',
                'X-Auth-Token' => @auth_token
              }.merge!(params[:headers] || {}),
              :host     => @host,
              :path     => "#{@path}/#{params[:path]}",
              :query    => ('ignore_awful_caching' << Time.now.to_i.to_s)
            }))
          rescue Excon::Errors::Unauthorized => error
            if ::JSON.parse(response.body)['unauthorized']['message'] == 'Invalid authentication token.  Please renew.'
              authenticate
              retry
            else
              raise error
            end
          rescue Excon::Errors::HTTPStatusError => error
            raise case error
            when Excon::Errors::NotFound
              Fog::HP::Compute::NotFound.slurp(error)
            else
              error
            end
          end
          unless response.body.empty?
            begin
              response.body = ::JSON.parse(response.body)
            rescue ::JSON::ParserError => error
              response.body    #### the body is not in JSON format so just return it as it is
            end
          end
          response
        end

        private

        def authenticate
          options = {
            :hp_secret_key  => @hp_secret_key,
            :hp_account_id  => @hp_account_id,
            :hp_auth_uri    => @hp_auth_uri,
          }
          credentials = Fog::HP.authenticate(options)
          @auth_token = credentials['X-Auth-Token']
          uri = URI.parse(credentials['X-Server-Management-Url'])
          @host   = @hp_servicenet == true ? "snet-#{uri.host}" : uri.host
          @path   = uri.path
          @port   = uri.port
          @scheme = uri.scheme
        end

      end
    end
  end
end
