class Merb::Cache
  attr_reader  :config, :store

  class StoreNotFound < Exception
    def initialize(cache_store)
      super("cache_store (#{cache_store}) not found (not implemented?)")
    end
  end

  DEFAULT_CONFIG = {
    :cache_html_directory => Merb.dir_for(:public) / "cache",

    #:store => "database",
    #:table_name => "merb_cache",

    #:disable => "development", # disable caching for development
    #:disable => true, # disable caching for all environments

    :store => "file",
    :cache_directory => Merb.root_path("tmp/cache"),

    #:store => "memcache",
    #:host => "127.0.0.1:11211",
    #:namespace => "merb_cache",
    #:track_keys => true,

    #:store => "memory",
    # store could be: file, memcache, memory, database, dummy, ...

    # can be nil|:snake|:tree|:hash|:query or a custom string
    # such as ":paramname1/:paramname2_and_:paramname3"
    #:cache_key_format => :snake,

    # expiration time in minutes
    #:cache_action_ttl => 10,
    #:cache_page_ttl => 10
  }

  # Called in the after_app_loads loop and instantiate the right backend
  #
  # ==== Raises
  # Store#NotFound::
  #   If the cache_store mentionned in the config is unknown
  def start
    @config = DEFAULT_CONFIG.merge(Merb::Plugins.config[:merb_cache] || {})
    if @config[:disable] == true || Merb.environment == @config[:disable]
      config[:disable_page_caching] = true
      config[:store] = "dummy"
    end
    @config[:cache_html_directory] ||= Merb.dir_for(:public) / "cache"
    require "merb_cache_more/cache-store/#{@config[:store]}"
    @store = Merb::Cache.const_get("#{@config[:store].capitalize}Store").new
    Merb.logger.info("Using #{@config[:store]} cache")
  rescue LoadError
    raise Merb::Cache::StoreNotFound, @config[:store].inspect
  end

  # Compute a cache key and yield it to the given block
  # It is used by the #expire_page, #expire_action and #expire methods.
  #
  # ==== Parameters
  # options<String, Hash>:: The key or the Hash that will be used to build the key
  # controller<String>:: The name of the controller
  # controller_based<Boolean>:: only used by action and page caching
  #
  # ==== Options (options)
  # :key<String>:: The complete or partial key that will be computed.
  # :action<String>:: The action name that will be used to compute the key
  # :controller<String>:: The controller name that will be part of the key
  # :params<Array[String]>::
  #   The params will be joined together (with '/') and added to the key
  # :match<Boolean, String>::
  #   true, it will try to match multiple cache entries
  #   string, shortcut for {:key => "mykey", :match => true}
  #
  # ==== Examples
  #   expire(:key => "root_key", :params => [session[:me], params[:id]])
  #   expire(:match => "root_key")
  #   expire_action(:action => 'list')
  #   expire_page(:action => 'show', :controller => 'news')
  #
  # ==== Returns
  # The result of the given block
  #
  def expire_key_for(options, controller, controller_based = false)
    key = ""
    if options.is_a? Hash
      case
      when key = options[:key]
      when action = options[:action]
        controller = options[:controller] || controller
        key = "/#{controller}/#{action}"
      when match = options[:match]
        key = match
      end
      if _params = options[:params]
        key += "/" + _params.join("/")
      end
      yield key, !options[:match].nil?
    else
      yield controller_based ? "/#{controller}/#{options}" : options, false
    end
  end

  # Compute a cache key based on the given parameters
  # Only used by the #cached_page?, #cached_action?, #cached?, #cache,
  # #cache_get and #cache_set methods
  #
  # ==== Parameters
  # options<String, Hash>:: The key or the Hash that will be used to build the key
  # controller<String>:: The name of the controller
  # controller_based<Boolean>:: only used by action and page caching
  #
  # ==== Options (options)
  # :key<String>:: The complete or partial key that will be computed.
  # :format<String>:: The formatting style that will be used for the key.
  # :action<String>:: The action name that will be used to compute the key
  # :controller<String>:: The controller name that will be part of the key
  # :params<Array[String]>::
  #   The params will be joined together (with '/') and added to the key
  #
  # ==== Examples
  #   cache_set("my_key", @data)
  #   cache_get(:key => "root_key", :params => [session[:me], params[:id]])
  #   cache_get(:key => "root_key", :format => nil|:snake|:hash|:query|:tree)
  #   cache_get(:key => "root_key", :format => ":one_:two[a]_and_:three[]")
  #
  # ==== Returns
  # The computed key
  # def key_for(options, controller = nil, controller_based = false)
  #   key = ""
  #   if options.is_a? Hash
  #     case
  #     when key = options[:key]
  #     when action = options[:action]
  #       controller = options[:controller] || controller
  #       key = "/#{controller}/#{action}"
  #     end
  # 
  #     _params = options[:params]
  #     _format = options[:format]
  # 
  #     if _params && !_params.empty?
  #       vals = _params.to_a.map {|p| String === p ? p : (Hash === p[1] ? p[1].values : p[1]) }.flatten
  #       case _format
  #       when nil
  #         _params = _params.to_a.flatten.join('_').gsub('/','%2F') # key1_val1_key2_val2
  #       when :snake
  #         _params = vals.join('_').gsub('/','%2F') # val1_val2
  #       when :hash
  #         _params = Digest::MD5.hexdigest(_params.to_s) # 32-bit md5 hash
  #       when :query
  #         _params = Merb::Request.params_to_query_string(_params) # key1=val1&key2=val2
  #       when :tree  
  #         _params = vals[0..10].map {|v| v.gsub('/','%2F')}.join('/') # /val1/val2
  #       else
  #         _params.each do |k,v| 
  #           _format.sub!(":#{k}", v.gsub('/','%2F')) if String === v
  #           _format.sub!(":#{k}[]", v[0].gsub('/','%2F')) if Array === v
  #           v.each {|kk,vv| _format.sub!(":#{k}[#{kk}]", vv.gsub('/','%2F')) } if Hash === v
  #         end
  #         _params = _format
  #       end
  #       key += '/' + sanitize_cache_key(_params) unless _params.blank?
  #     else
  #       #key += '/index' # all pages in one dir
  #     end
  #   else
  #     key = controller_based ? "/#{controller}/#{options}" : options
  #   end
  #   key
  # end
  #
  def key_for(options, controller = nil, controller_based = false)
    key = ""
    if options.is_a? Hash
      case
      when key = options[:key]
      when action = options[:action]
        controller = options[:controller] || controller
        key = "/#{controller}/#{action}"
      end

      _params = options[:params]
      _format = options[:format]

      if _params && !_params.empty?
        vals = _params.to_a.map {|p| String === p ? p : (Hash === p[1] ? p[1].values : p[1]) }.flatten
        case _format
        when nil
          _params = _params.to_a.flatten.join('_').gsub('/','%2F') # key1_val1_key2_val2
        when :snake
          _params = vals.join('_').gsub('/','%2F') # val1_val2
        when :hash
          _params = Digest::MD5.hexdigest(_params.to_s) # 32-bit md5 hash
        when :query
          _params = Merb::Request.params_to_query_string(_params) # key1=val1&key2=val2
        when :tree  
          _params = vals[0..10].map {|v| v.gsub('/','%2F')}.join('/') # /val1/val2
        else
          _params.each do |k,v| 
            _format.sub!(":#{k}", v.gsub('/','%2F')) if String === v
            _format.sub!(":#{k}[]", v[0].gsub('/','%2F')) if Array === v
            v.each {|kk,vv| _format.sub!(":#{k}[#{kk}]", vv.gsub('/','%2F')) } if Hash === v
          end
          _params = _format
        end
        key += '/' + sanitize_cache_key(_params) unless _params.blank?
      else
        #key += '/index' # all pages in one dir
      end
    else
      key = controller_based ? "/#{controller}/#{options}" : options
    end
    key
  end

  # Removes illegal chars from key and allows cached pages to be safely
  # stored on any filesystem. You may override this method in your app 
  # to match how filenames are escaped by your web server.
  #
  # ==== Parameters
  # key<String>:: The key to sanitize
  #
  # ==== Returns
  # The sanitized key
  #
  def sanitize_cache_key(key = "")
    key.gsub(/[\\\:\*\?\"\<\>\|\s]/,'_')
  end

  module ControllerInstanceMethods
    # Mixed in Merb::Controller and provides expire_all for action and fragment caching.
    def expire_all
      Merb::Controller._cache.store.expire_all
    end
  end
end

