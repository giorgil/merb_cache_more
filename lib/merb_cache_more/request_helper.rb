module Merb
  module Test
    module RequestHelper
      # Dispatches an action to the given class. This bypasses the router and is
      # suitable for unit testing of controllers.
      #
      # ==== Parameters
      # controller_klass<Controller>::
      #   The controller class object that the action should be dispatched to.
      # action<Symbol>:: The action name, as a symbol.
      # params<Hash>::
      #   An optional hash that will end up as params in the controller instance.
      # env<Hash>::
      #   An optional hash that is passed to the fake request. Any request options
      #   should go here (see +fake_request+), including :req or :post_body
      #   for setting the request body itself.
      # &blk::
      #   The controller is yielded to the block provided for actions *prior* to
      #   the action being dispatched.
      #
      # ==== Example
      #   dispatch_to(MyController, :create, :name => 'Homer' ) do
      #     self.stub!(:current_user).and_return(@user)
      #   end
      #
      # ==== Notes
      # Does not use routes.
      #
      #---
      # @public
      def dispatch_to(controller_klass, action, params = {}, env = {}, &blk)
        action = action.to_s
        request_body = { :post_body => env[:post_body], :req => env[:req] }
        env = env.merge(:query_string => Merb::Request.params_to_query_string(params)) unless env.key?('QUERY_STRING')
        request = fake_request(env, request_body)
        dispatch_request(request, controller_klass, action, &blk)
      end
    end
  end
end
