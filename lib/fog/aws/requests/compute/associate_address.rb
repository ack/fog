module Fog
  module Compute
    class AWS
      class Real

        require 'fog/aws/parsers/compute/basic'

        # Associate an elastic IP address with an instance
        #
        # ==== Parameters
        # * instance_id<~String> - Id of instance to associate address with
        # * public_ip<~String> - Public ip to assign to instance
        # * allocation_id<~String> - (optional) Allocation Id (required for VPC instances only)
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'return'<~Boolean> - success?
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AssociateAddress.html]
        def associate_address(instance_id, public_ip, allocation_id=nil)
          key, identifier = 'PublicIp', public_ip
          if allocation_id
            key, identifier = 'AllocationId', allocation_id
          end
          
          request(
            'Action'      => 'AssociateAddress',
            'InstanceId'  => instance_id,
            key           => identifier,
            :idempotent   => true,
            :parser       => Fog::Parsers::Compute::AWS::Basic.new
          )
        end

      end

      class Mock

        def associate_address(instance_id, public_ip, allocation_id=nil)
          response = Excon::Response.new
          response.status = 200
          instance = self.data[:instances][instance_id]
          address = self.data[:addresses][public_ip]
          if instance && address
            if current_instance = self.data[:instances][address['instanceId']]
              current_instance['ipAddress'] = current_instance['originalIpAddress']
            end
            address['instanceId'] = instance_id
            # detach other address (if any)
            if self.data[:addresses][instance['ipAddress']]
              self.data[:addresses][instance['ipAddress']]['instanceId'] = nil
            end
            instance['ipAddress'] = public_ip
            instance['dnsName'] = Fog::AWS::Mock.dns_name_for(public_ip)
            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'return'    => true
            }
            response
          elsif !instance
            raise Fog::Compute::AWS::NotFound.new("The instance ID '#{instance_id}' does not exist")
          elsif !address
            raise Fog::Compute::AWS::Error.new("AuthFailure => The address '#{public_ip}' does not belong to you.")
          end
        end

      end
    end
  end
end
