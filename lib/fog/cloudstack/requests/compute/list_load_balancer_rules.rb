module Fog
  module Compute
    class Cloudstack
      class Real

        # Lists resource limits.
        #
        # {CloudStack API Reference}[http://download.cloud.com/releases/2.2.0/api_2.2.4/global_admin/listLoadBalancerRules.html]
        def list_load_balancer_rules(options={})
          options.merge!(
            'command' => 'listLoadBalancerRules'
          )
          
          request(options)
        end

      end
    end
  end
end


