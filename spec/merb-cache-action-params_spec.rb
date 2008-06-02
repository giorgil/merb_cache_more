describe "merb-cache-action-params" do
  
  qs = "p1=abc&p2=456&p3=ghi"

  it "should cache action (action3) with params in default format" do
    c = get("/cache_controller/action3", {}, {:query_string => qs})
    c.body.strip.should == "test action3"
    c.cached?(:key => "/cache_controller/action3/p1_abc_p2_456_p3_ghi").should be_true
    c.cache_get(:key => "/cache_controller/action3/p1_abc_p2_456_p3_ghi").should == "test action3"
  end

  it "should expire action (action3) with params in default format" do
    c = get("/cache_controller/action3", {}, {:query_string => qs})
    c.expire_action(:key => "/cache_controller/action3/p1_abc_p2_456_p3_ghi")
    c.cache_get(:key => "/cache_controller/action3/p1_abc_p2_456_p3_ghi").should be_nil
  end
  
  it "should cache action (action3) with full path and params in default format" do
    c = get("/cache_controller/action3/foo/bar", {}, {:query_string => qs})
    c.body.strip.should == "test action3"
    c.cached?(:key => "/cache_controller/action3/foo/bar/p1_abc_p2_456_p3_ghi").should be_true
    c.cache_get(:key => "/cache_controller/action3/foo/bar/p1_abc_p2_456_p3_ghi").should == "test action3"
  end
  
  it "should expire action (action3) with full path and params in default format" do
    c = get("/cache_controller/action3/foo/bar", {}, {:query_string => qs})
    c.expire_action(:key => "/cache_controller/action3/foo/bar/p1_abc_p2_456_p3_ghi")
    c.cache_get(:key => "/cache_controller/action3/foo/bar/p1_abc_p2_456_p3_ghi").should be_nil
  end

  it "should cache action (action12) with specific params" do
    c = get("/cache_controller/action12", {}, {:query_string => qs})
    c.cached?(:key => "/cache_controller/action12/p1_abc_p2_456").should be_true
    c.cache_get(:key => "/cache_controller/action12/p1_abc_p2_456").should == "test action12"
  end

  it "should expire action (action12) with specific params" do
    c = get("/cache_controller/action12", {}, {:query_string => qs})
    c.expire_action(:key => "/cache_controller/action12/p1_abc_p2_456")
    c.cache_get(:key => "/cache_controller/action12/p1_abc_p2_456").should be_nil
  end
  
  it "should cache actions with params in every key format" do
    c = get("/cache_controller/action13", {}, {:query_string => qs}) # snake
    c.cached?(:key => "/cache_controller/action13/abc_456_ghi").should be_true
  
    c = get("/cache_controller/action14", {}, {:query_string => qs}) # tree
    c.cached?(:key => "/cache_controller/action14/abc/456/ghi").should be_true
  
    c = get("/cache_controller/action15", {}, {:query_string => qs}) # hash
    c.cached?(:key => "/cache_controller/action15/" + Digest::MD5.hexdigest("p1abcp2456p3ghi")).should be_true
  
    c = get("/cache_controller/action16", {}, {:query_string => qs}) # query
    c.cached?(:key => "/cache_controller/action16/p1=abc&p2=456&p3=ghi").should be_true
  
    c = get("/cache_controller/action17", {}, {:query_string => qs}) # custom
    c.cached?(:key => "/cache_controller/action17/abc/456_and_ghi").should be_true
  end

  it "should expire actions with params in every key format" do
    CACHE.expire_action(:key => "/cache_controller/action13/abc_456_ghi")
    CACHE.cached?(:key => "/cache_controller/action13/abc_456_ghi").should be_false

    CACHE.expire_action(:key => "/cache_controller/action14/abc/456/ghi")
    CACHE.cached?(:key => "/cache_controller/action14/abc/456/ghi").should be_false

    CACHE.expire_action(:key => "/cache_controller/action15/" + Digest::MD5.hexdigest("p1abcp2456p3ghi"))
    CACHE.cached?(:key => "/cache_controller/action15/" + Digest::MD5.hexdigest("p1abcp2456p3ghi")).should be_false

    CACHE.expire_action(:key => "/cache_controller/action16/p1=abc&p2=456&p3=ghi")
    CACHE.cached?(:key => "/cache_controller/action16/p1=abc&p2=456&p3=ghi").should be_false

    CACHE.expire_action(:key => "/cache_controller/action17/abc/456_and_ghi")
    CACHE.cached?(:key => "/cache_controller/action17/abc/456_and_ghi").should be_false
  end
end
