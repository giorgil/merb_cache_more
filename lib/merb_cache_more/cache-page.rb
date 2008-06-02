class Merb::Cache
  cattr_accessor :cached_pages
  self.cached_pages = {}
end

module Merb::Cache::ControllerClassMethods
  # Mixed in Merb::Controller. Provides class methods related to page caching
  # Page caching is mostly action caching with file backend using its own output directory of .html files

  # Register the action for page caching
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
  #   cache_page :mostly_static
  #   cache_page :barely_dynamic, 10
  #   cache_page :barely_dynamic, 10, {:format => :hash, :params => [:id, :name]}
  #   cache_page :barely_dynamic, :format => ":param1/:param2-and_:param3[key]"
  def cache_page(action, from_now = nil, opts = {})
    from_now, opts = nil, from_now if Hash === from_now

    cache_opts = {:format => opts[:format], :params => opts[:params]}
    opts.delete(:format); opts.delete(:params); opts.delete(:exclude)
    
    before("cache_#{action}_before", opts.merge(:only => action, :with => [cache_opts]))
    after("cache_#{action}_after", opts.merge(:only => action, :with => [cache_opts]))
    alias_method "cache_#{action}_before", :cache_page_before
    alias_method "cache_#{action}_after", :cache_page_after
    
    _pages = Merb::Cache.cached_pages[controller_name] ||= {}
    _pages[action] = [from_now, 0]
  end

  # Register actions for page caching (before and after filters)
  #
  # ==== Parameter
  # actions<Symbol,Array[Symbol,~minutes,Hash]>:: See #cache_page
  #
  # ==== Example
  #   cache_pages :mostly_static,  :barely_dynamic
  #   cache_pages :mostly_static,  [:barely_dynamic, 10]
  #   cache_pages :barely_dynamic, [:barely_dynamic, 10, :format => :hash]
  #   cache_pages :barely_dynamic, [:barely_dynamic, 10, :params => [:id, :name]]
  #   cache_pages :all, 10, :exclude => [:show], :format => :snake, :params => [:id, :name]
  def cache_pages(*pages)
    config = Merb::Plugins.config[:merb_cache]
    
    if pages[0] == :all
      from_now = Hash === pages[1] ? config[:cache_page_ttl] : pages[1]
      opts     = Hash === pages[1] ? pages[1] : pages[2] || {}
      excludes = opts[:exclude] || []
      pages    = self.instance_methods(false).map {|action|
        [action.to_sym, from_now, opts] unless excludes.include?(action.to_sym)
      }.compact
    end

    pages.each do |page_opts|
      if Array === page_opts
        action   = page_opts[0]
        from_now = Hash === page_opts[1] ? config[:cache_page_ttl] : page_opts[1]
        opts     = Hash === page_opts[1] ? page_opts[1] : page_opts[2]
      else
        action   = page_opts
        from_now = config[:cache_page_ttl]
        opts     = {}
      end
      cache_page(action, from_now, opts||{})
    end
    true
  end
end

module Merb::Cache::ControllerInstanceMethods
  # Mixed in Merb::Controller. Provides methods related to page caching

  DEFAULT_PAGE_EXTENSION = 'html'

  # Checks whether a cache entry exists
  #
  # ==== Parameter
  # options<String,Hash>:: The options that will be passed to #key_for
  #
  # ==== Returns
  # true if the cache entry exists, false otherwise
  #
  # ==== Example
  #   cached_page?(:action => 'show', :params => [params[:page]])
  #   cached_page?(:action => 'show', :extension => 'js')
  def cached_page?(options)
    key = Merb::Controller._cache.key_for(options, controller_name, true)
    extension = options[:extension] || DEFAULT_PAGE_EXTENSION
    File.file?(Merb::Controller._cache.config[:cache_html_directory] / "#{key}.#{extension}")
  end

  # Expires the page identified by the key computed after the parameters
  #
  # ==== Parameter
  # options<String,Hash>:: The options that will be passed to #expire_key_for
  #
  # ==== Examples (See Merb::Cache#expire_key_for for more options)
  #   # will expire path/to/page/cache/news/show/1.html
  #   expire_page(:key => url(:news,News.find(1)))
  #
  #   # will expire path/to/page/cache/news/show.html
  #   expire_page(:action => 'show', :controller => 'news')
  #
  #   # will expire path/to/page/cache/news/show*
  #   expire_page(:action => 'show', :match => true)
  #
  #   # will expire path/to/page/cache/news/show.js
  #   expire_page(:action => 'show', :extension => 'js')
  def expire_page(options)
    config_dir = Merb::Controller._cache.config[:cache_html_directory]
    Merb::Controller._cache.expire_key_for(options, controller_name, true) do |key, match|
      if match
        files = Dir.glob(config_dir / "#{key}*")
      else
        extension = options[:extension] || DEFAULT_PAGE_EXTENSION
        files = config_dir / "#{key}.#{extension}"
      end
      FileUtils.rm_rf(files)
    end
    true
  end

  # Expires all the pages stored in config[:cache_html_directory]
  def expire_all_pages
    FileUtils.rm_rf(Dir.glob(Merb::Controller._cache.config[:cache_html_directory] / "*"))
  end

  # You can call this method if you need to prevent caching the page
  # after it has been rendered.
  def abort_cache_page
    @capture_page = false
  end

  private

  # Called by the before and after filters. Stores or recalls a cache entry.
  # The name used for the cache file is based on request.path
  # If the name ends with "/" then it is removed
  # If the name is "/" then it will be replaced by "index"
  #
  # ==== Parameters
  # data<String>:: the data to put in cache
  #
  # ==== Examples
  #   All the file are written to config[:cache_html_directory]
  #   If request.path is "/", the name will be "/index.html"
  #   If request.path is "/news/show/1", the name will be "/news/show/1.html"
  #   If request.path is "/news/show/", the name will be "/news/show.html"
  #   If request.path is "/news/styles.css", the name will be "/news/styles.css"
  def _cache_page(data = nil, opts = {})
    return if Merb::Controller._cache.config[:disable_page_caching]
    controller = controller_name
    action = action_name.to_sym
    pages = Merb::Controller._cache.cached_pages[controller]
    return unless pages && pages.key?(action)

    path = request.path.chomp("/")
    path = "index" if path.empty?

    _format = opts[:format] || Merb::Controller._cache.config[:cache_key_format]
    _params = opts[:params]==false ? nil : Merb::Request.query_parse(request.query_string, '&', true)
    _params.delete_if {|k,v| !opts[:params].include?(k.to_sym) } if _params && opts[:params]
 
    key = Merb::Controller._cache.key_for({:key => path, :params => _params, :format => _format})

    no_format = params[:format].nil? || params[:format].empty?
    ext = "." + (no_format ? DEFAULT_PAGE_EXTENSION : params[:format])
    ext = nil if File.extname(key) == ext
    cache_file = Merb::Controller._cache.config[:cache_html_directory] / "#{key}#{ext}"

    if data
      cache_directory = File.dirname(cache_file)
      FileUtils.mkdir_p(cache_directory)
      _expire_in = pages[action][0]
      pages[action][1] = _expire_in.minutes.from_now unless _expire_in.nil?
      cache_write_page(cache_file, data)
      Merb.logger.info("cache: set (#{path})")
    else
      @capture_page = false
      if File.file?(cache_file)
        _data = cache_read_page(cache_file)
        _expire_in, _expire_at = pages[action]
        if _expire_in.nil? || Time.now.to_i < _expire_at.to_i
          Merb.logger.info("cache: hit (#{path})")
          throw(:halt, _data)
        end
        FileUtils.rm_f(cache_file)
      end
      @capture_page = true
    end
    true
  end

  # Read data from a file using exclusive lock
  #
  # ==== Parameters
  # cache_file<String>:: the full path to the file
  #
  # ==== Returns
  # data<String>:: the data that has been read from the file
  def cache_read_page(cache_file)
    _data = nil
    File.open(cache_file, "r") do |cache_data|
      cache_data.flock(File::LOCK_EX)
      _data = cache_data.read
      cache_data.flock(File::LOCK_UN)
    end
    _data
  end

  # Write data to a file using exclusive lock
  #
  # ==== Parameters
  # cache_file<String>:: the full path to the file
  # data<String>:: the data that will be written to the file
  def cache_write_page(cache_file, data)
    File.open(cache_file, "w+") do |cache_data|
      cache_data.flock(File::LOCK_EX)
      cache_data.write(data)
      cache_data.flock(File::LOCK_UN)
    end
    true
  end

  # before filter
  def cache_page_before(opts)
    # recalls a cached entry or set @capture_page to true in order
    # to grab the response in the after filter
    _cache_page(nil, opts)
  end

  # after filter
  def cache_page_after(opts)
    # takes the body of the response
    # if the cache entry expired, if it doesn't exist or status is 200
    _cache_page(body, opts) if @capture_page && status == 200
  end
end
