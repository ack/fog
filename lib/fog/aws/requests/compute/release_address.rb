module Fog
  module Compute
    class AWS
      class Real

        require 'fog/aws/parsers/compute/basic'

        # Release an elastic IP address.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'return'<~Boolean> - success?
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ReleaseAddress.html]
        def release_address(public_ip, allocation_id=nil)
          key, identifier = 'PublicIp', public_ip
          if allocation_id
            key, identifier = 'AllocationId', allocation_id
          end
          
          request(
            'Action'    => 'ReleaseAddress',
            key         => identifier,
            :idempotent => true,
            :parser     => Fog::Parsers::Compute::AWS::Basic.new
          )
        end

      end

      class Mock

        def release_address(public_ip, allocation_id=nil)
          response = Excon::Response.new
          if (address = self.data[:addresses].delete(public_ip))
            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'return'    => true
            }
            response
          else
            raise Fog::Compute::AWS::Error.new("AuthFailure => The address '#{public_ip}' does not belong to you.")
          end
        end

      end
    end
  end
end
