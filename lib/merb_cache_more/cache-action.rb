class Merb::Cache
  cattr_accessor :cached_actions
  self.cached_actions = {}
end

module Merb::Cache::ControllerClassMethods
  # Mixed in Merb::Controller. Provides methods related to action caching

  # Register the action for action caching
  #
  # ==== Parameters
  # action<Symbol>:: The name of the action to register
  # from_now<~minutes>::
  #   The number of minutes (from now) the cache should persist
  # options<Hash>::
  #   Key formats :format => :snake|:tree|:hash|:query or nil for default
  #   Custom format :format => ":param1/:param2-and_:param3"
  #   Params :params => [params to include] or false to disable
  #
  # ==== Examples
  #   cache_action :mostly_static
  #   cache_action :barely_dynamic, 10
  #   cache_action :barely_dynamic, 10, {:format => :hash, :params => [:id, :name]}
  #   cache_action :barely_dynamic, :format => ":param1/:param2-and_:param3[key]"
  def cache_action(action, from_now = nil, opts = {})
    from_now, opts = nil, from_now if Hash === from_now

    cache_opts = {:format => opts[:format], :params => opts[:params]}
    opts.delete(:format); opts.delete(:params); opts.delete(:exclude)
    
    before("cache_#{action}_before", opts.merge(:only => action, :with => [cache_opts]))
    after("cache_#{action}_after", opts.merge(:only => action, :with => [cache_opts]))
    alias_method "cache_#{action}_before", :cache_action_before
    alias_method "cache_#{action}_after", :cache_action_after
    
    _actions = Merb::Cache.cached_actions[controller_name] ||= {}
    _actions[action] = from_now
  end

  # Register actions for action caching (before and after filters)
  #
  # ==== Parameter
  # actions<Symbol,Array[Symbol,~minutes,Hash]>:: See #cache_action
  #
  # ==== Example
  #   cache_actions :mostly_static,  :barely_dynamic
  #   cache_actions :mostly_static,  [:barely_dynamic, 10]
  #   cache_actions :barely_dynamic, [:barely_dynamic, 10, :format => :hash]
  #   cache_actions :barely_dynamic, [:barely_dynamic, 10, :params => [:id, :name]]
  #   cache_actions :all, 10, :exclude => [:show], :format => :snake, :params => [:id, :name]
  def cache_actions(*actions)
    config = Merb::Plugins.config[:merb_cache]
    
    if actions[0] == :all
      from_now = Hash === actions[1] ? config[:cache_action_ttl] : actions[1]
      opts     = Hash === actions[1] ? actions[1] : actions[2] || {}
      excludes = opts[:exclude] || []
      actions  = self.instance_methods(false).map {|action| 
        [action.to_sym, from_now, opts] unless excludes.include?(action.to_sym)
      }.compact
    end

    actions.each do |act_opts|
      if Array === act_opts
        action   = act_opts[0]
        from_now = Hash === act_opts[1] ? config[:cache_action_ttl] : act_opts[1]
        opts     = Hash === act_opts[1] ? act_opts[1] : act_opts[2]
      else
        action   = act_opts
        from_now = config[:cache_action_ttl]
        opts     = {}
      end
      cache_action(action, from_now, opts||{})
    end
    true
  end
end

module Merb::Cache::ControllerInstanceMethods
  # Mixed in Merb::Controller. Provides methods related to action caching

  # Checks whether a cache entry exists
  #
  # ==== Parameter
  # options<String,Hash>:: The options that will be passed to #key_for
  #
  # ==== Returns
  # true if the cache entry exists, false otherwise
  #
  # ==== Example
  #   cached_action?(:action => 'show', :params => [params[:page]])
  def cached_action?(options)
    key = Merb::Controller._cache.key_for(options, controller_name, true)
    Merb::Controller._cache.store.cached?(key)
  end

  # Expires the action identified by the key computed after the parameters
  #
  # ==== Parameter
  # options<String,Hash>:: The options that will be passed to #expire_key_for
  #
  # ==== Examples
  #   expire_action(:action => 'show', :controller => 'news')
  #   expire_action(:action => 'show', :match => true)
  def expire_action(options)
    Merb::Controller._cache.expire_key_for(options, controller_name, true) do |key, match|
      if match
        Merb::Controller._cache.store.expire_match(key)
      else
        Merb::Controller._cache.store.expire(key)
      end
    end
    true
  end

  # You can call this method if you need to prevent caching the action
  # after it has been rendered.
  def abort_cache_action
    @capture_action = false
  end

  private

  # Called by the before and after filters. Stores or recalls a cache entry.
  # The key is based on the result of request.path
  # If the key with "/" then it is removed
  # If the key is "/" then it will be replaced by "index"
  #
  # ==== Parameters
  # data<String>:: the data to put in cache using the cache store
  #
  # ==== Examples
  #   If request.path is "/", the key will be "index"
  #   If request.path is "/news/show/1", the key will be "/news/show/1"
  #   If request.path is "/news/show/", the key will be "/news/show"
  def _cache_action(data = nil, opts = {})
    controller = controller_name
    action = action_name.to_sym
    actions = Merb::Controller._cache.cached_actions[controller]
    return unless actions && actions.key?(action)

    path = request.path.chomp("/")
    path = "index" if path.empty?

    _format = opts[:format] || Merb::Controller._cache.config[:cache_key_format]
    _params = opts[:params]==false ? nil : Merb::Request.query_parse(request.query_string, '&', true)
    _params.delete_if {|k,v| !opts[:params].include?(k.to_sym) } if _params && opts[:params]
    
    key = Merb::Controller._cache.key_for({:key => path, :params => _params, :format => _format})

    if data
      from_now = Merb::Controller._cache.cached_actions[controller][action]
      Merb::Controller._cache.store.cache_set(key, data, from_now)
    else
      @capture_action = false
      _data = Merb::Controller._cache.store.cache_get(key)
      throw(:halt, _data) unless _data.nil?
      @capture_action = true
    end
    true
  end

  # before filter
  def cache_action_before(opts)
    # recalls a cached entry or set @capture_action to true in order
    # to grab the response in the after filter
    _cache_action(nil, opts)
  end

  # after filter
  def cache_action_after(opts)
    # takes the body of the response and put it in cache
    # if the cache entry expired, if it doesn't exist or status is 200
    _cache_action(body, opts) if @capture_action && status == 200
  end
end
