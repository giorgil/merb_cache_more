module Merb
  class Request
    class << self
      # ==== Parameters
      # value<Array, Hash, Dictionary ~to_s>:: The value for the query string.
      # prefix<~to_s>:: The prefix to add to the query string keys.
      #
      # ==== Returns
      # String:: The query string.
      #
      # ==== Alternatives
      # If the value is a string, the prefix will be used as the key.
      #
      # ==== Examples
      #   params_to_query_string(10, "page")
      #     # => "page=10"
      #   params_to_query_string({ :page => 10, :word => "ruby" })
      #     # => "page=10&word=ruby"
      #   params_to_query_string({ :page => 10, :word => "ruby" }, "search")
      #     # => "search[page]=10&search[word]=ruby"
      #   params_to_query_string([ "ice-cream", "cake" ], "shopping_list")
      #     # => "shopping_list[]=ice-cream&shopping_list[]=cake"
      def params_to_query_string(value, prefix = nil)
        case value
        when Array
          value.map { |v|
            params_to_query_string(v, "#{prefix}[]")
          } * "&"
        when Hash, Dictionary
          value.map { |k, v|
            params_to_query_string(v, prefix ? "#{prefix}[#{Merb::Request.escape(k)}]" : Merb::Request.escape(k))
          } * "&"
        else
          "#{prefix}=#{Merb::Request.escape(value)}"
        end
      end
      
      # ==== Parameters
      # qs<String>:: The query string.
      # d<String>:: The query string divider. Defaults to "&".
      # preserve_order<Boolean>:: Preserve order of args. Defaults to false.
      #
      # ==== Returns
      # Mash:: The parsed query string (Dictionary if preserve_order is set).
      #
      # ==== Examples
      #   query_parse("bar=nik&post[body]=heya")
      #     # => { :bar => "nik", :post => { :body => "heya" } }
      def query_parse(qs, d = '&;', preserve_order = false)
        qh = preserve_order ? Dictionary.new : {}
        (qs||'').split(/[#{d}] */n).inject(qh) { |h,p| 
          key, value = unescape(p).split('=',2)
          normalize_params(h, key, value)
        }
        preserve_order ? qh : qh.to_mash
      end
    end
  end
end    
