describe "cache key generator" do
  
  u1 = "/items/list"
  q1 = "key1=val1&key2[a]=val2a&key3[]=val3a&key3[]=val3b"
  p1 = Merb::Request.query_parse(q1, '&', true)

  u2 = "http://www.google.com"
  q2 = "q=cache:MrZoPWIJNhIJ:www.merbivore.com/+merb&hl=en&ct=clnk&cd=1"
  p2 = Merb::Request.query_parse(q2, '&', true)

  it "should return a default key" do
    CACHE._cache.key_for({:key => u1, :format => nil, :params => nil}).should == "/items/list"
    CACHE._cache.key_for({:key => u2, :format => nil, :params => nil}).should == "http://www.google.com"
  end

  it "should return a default key using params" do
    CACHE._cache.key_for({:key => u1, :format => nil, :params => p1}).should == "/items/list/key1_val1_key2_aval2a_key3_val3a_val3b"
    CACHE._cache.key_for({:key => u2, :format => nil, :params => p2}).should == "http://www.google.com/q_cache_MrZoPWIJNhIJ_www.merbivore.com%2F_merb_hl_en_ct_clnk_cd_1"
  end

  it "should return a snake key using params" do
    CACHE._cache.key_for({:key => u1, :format => :snake, :params => p1}).should == "/items/list/val1_val2a_val3a_val3b"
    CACHE._cache.key_for({:key => u2, :format => :snake, :params => p2}).should == "http://www.google.com/cache_MrZoPWIJNhIJ_www.merbivore.com%2F_merb_en_clnk_1"
  end

  it "should return a hash key using params" do
    CACHE._cache.key_for({:key => u1, :format => :hash, :params => p1}).should match(/^\/items\/list\/[a-z0-9]{32}$/i)
    CACHE._cache.key_for({:key => u2, :format => :hash, :params => p2}).should match(/^http\:\/\/www.google.com\/[a-z0-9]{32}$/i)
  end

  it "should return a tree key using params" do
    CACHE._cache.key_for({:key => u1, :format => :tree, :params => p1}).should == "/items/list/val1/val2a/val3a/val3b"
    CACHE._cache.key_for({:key => u2, :format => :tree, :params => p2}).should == "http://www.google.com/cache_MrZoPWIJNhIJ_www.merbivore.com%2F_merb/en/clnk/1"
  end

  it "should return a query key using params" do
    CACHE._cache.key_for({:key => u1, :format => :query, :params => p1}).should == "/items/list/key1=val1&key2[a]=val2a&key3[]=val3a&key3[]=val3b"
    CACHE._cache.key_for({:key => u2, :format => :query, :params => p2}).should == "http://www.google.com/q=cache%3AMrZoPWIJNhIJ%3Awww.merbivore.com%2F+merb&hl=en&ct=clnk&cd=1"
  end

  it "should return a custom key using params" do
    CACHE._cache.key_for({:key => u1, :format => ":key1/:key2[a]_and_:key3[]", :params => p1}).should == "/items/list/val1/val2a_and_val3a"
    CACHE._cache.key_for({:key => u2, :format => ":q/:hl_:ct_and_:cd", :params => p2}).should == "http://www.google.com/cache_MrZoPWIJNhIJ_www.merbivore.com%2F_merb/en_clnk_and_1"
  end
end
