describe "merb-cache-page-params" do
  
  qs = "p1=abc&p2=456&p3=ghi"

  it "should cache page (action5) with params in default format" do
    c = get("/cache_controller/action5", {}, {:query_string => qs})
    c.body.strip.should == "test action5"
    c.cached_page?(:key => "/cache_controller/action5/p1_abc_p2_456_p3_ghi").should be_true
  end
  
  it "should expire page (action5) with params in default format" do
    c = get("/cache_controller/action5", {}, {:query_string => qs})
    c.expire_page(:key => "/cache_controller/action5/p1_abc_p2_456_p3_ghi")
    c.cached_page?(:key => "/cache_controller/action5/p1_abc_p2_456_p3_ghi").should be_false
  end

  it "should cache page (action5) with full path and params in default format" do
    c = get("/cache_controller/action5/foo/bar", {}, {:query_string => qs})
    c.body.strip.should == "test action5"
    c.cached_page?(:key => "/cache_controller/action5/foo/bar/p1_abc_p2_456_p3_ghi").should be_true
  end
  
  it "should expire page (action5) with full path and params in default format" do
    c = get("/cache_controller/action5/foo/bar", {}, {:query_string => qs})
    c.expire_page(:key => "/cache_controller/action5/foo/bar/p1_abc_p2_456_p3_ghi")
    c.cached_page?(:key => "/cache_controller/action5/foo/bar/p1_abc_p2_456_p3_ghi").should be_false
  end

  it "should cache page (action18) with specific params" do
    c = get("/cache_controller/action18", {}, {:query_string => qs})
    c.cached_page?(:key => "/cache_controller/action18/p1_abc_p2_456").should be_true
  end

  it "should expire page (action18) with specific params" do
    c = get("/cache_controller/action18", {}, {:query_string => qs})
    c.expire_page(:key => "/cache_controller/action18/p1_abc_p2_456")
    c.cached_page?(:key => "/cache_controller/action18/p1_abc_p2_456").should be_false
  end
  
  it "should cache pages with params in every key format" do
    c = get("/cache_controller/action19", {}, {:query_string => qs}) # snake
    c.cached_page?(:key => "/cache_controller/action19/abc_456_ghi").should be_true
  
    c = get("/cache_controller/action20", {}, {:query_string => qs}) # tree
    c.cached_page?(:key => "/cache_controller/action20/abc/456/ghi").should be_true
  
    c = get("/cache_controller/action21", {}, {:query_string => qs}) # hash
    c.cached_page?(:key => "/cache_controller/action21/" + Digest::MD5.hexdigest("p1abcp2456p3ghi")).should be_true
  
    c = get("/cache_controller/action22", {}, {:query_string => qs}) # query
    c.cached_page?(:key => "/cache_controller/action22/p1=abc&p2=456&p3=ghi").should be_true
  
    c = get("/cache_controller/action23", {}, {:query_string => qs}) # custom
    c.cached_page?(:key => "/cache_controller/action23/abc/456_and_ghi").should be_true
  end

  it "should expire pages with params in every key format" do
    CACHE.expire_page(:key => "/cache_controller/action19/abc_456_ghi")
    CACHE.cached_page?(:key => "/cache_controller/action19/abc_456_ghi").should be_false

    CACHE.expire_page(:key => "/cache_controller/action20/abc/456/ghi")
    CACHE.cached_page?(:key => "/cache_controller/action20/abc/456/ghi").should be_false

    CACHE.expire_page(:key => "/cache_controller/action21/" + Digest::MD5.hexdigest("p1abcp2456p3ghi"))
    CACHE.cached_page?(:key => "/cache_controller/action21/" + Digest::MD5.hexdigest("p1abcp2456p3ghi")).should be_false

    CACHE.expire_page(:key => "/cache_controller/action22/p1=abc&p2=456&p3=ghi")
    CACHE.cached_page?(:key => "/cache_controller/action22/p1=abc&p2=456&p3=ghi").should be_false

    CACHE.expire_page(:key => "/cache_controller/action23/abc/456_and_ghi")
    CACHE.cached_page?(:key => "/cache_controller/action23/abc/456_and_ghi").should be_false
  end

  it "should expire all pages" do
    CACHE.expire_all_pages
    CACHE.cached_page?("action6").should be_false
    Dir.glob(Merb::Controller._cache.config[:cache_html_directory] + '/*').should be_empty
  end
end
