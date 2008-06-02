class CacheController < Merb::Controller
  self._template_root = File.dirname(__FILE__) / "views"
  before :fix_query_string

  cache_action :action3
  cache_action :action4, 0.05
  #cache_actions :action3, [:action4, 0.05]

  cache_page :action5
  cache_page :action6, 0.05
  #cache_pages :action5, [:action6, 0.05]
  cache_page :action7
  
  cache_action :action8, 0.05, :if => proc {|controller| !controller.params[:id].empty?}
  cache_action :action9, 0.05, :unless => proc {|controller| controller.params[:id].empty?}
  cache_action :action10, :if => :non_empty_id?
  cache_action :action11, :unless => :empty_id?

  cache_action :action12, :params => [:p1, :p2]
  cache_action :action13, :format => :snake
  cache_action :action14, :format => :tree
  cache_action :action15, :format => :hash
  cache_action :action16, :format => :query
  cache_action :action17, :format => ":p1/:p2_and_:p3"

  cache_page :action18, :params => [:p1, :p2]
  cache_page :action19, :format => :snake
  cache_page :action20, :format => :tree
  cache_page :action21, :format => :hash
  cache_page :action22, :format => :query
  cache_page :action23, :format => ":p1/:p2_and_:p3"

  def fix_query_string
    params[:id] ||= ''
    p = Merb::Request.query_parse(request.query_string, '&', true)
    p.delete_if {|k,v| [:id,:format].include?(k.to_sym) }
    request.env['QUERY_STRING'] = Merb::Request.params_to_query_string(p)
  end

  def index; "test index" end
  def action1; render end
  def action2; render end
  def action3; "test action3" end
  def action4; "test action4" end
  def action5; "test action5" end
  def action6; Time.now.to_s  end
  def action8; "test action8" end
  def action9; "test action9" end
  def action10; "test action10" end
  def action11; "test action11" end
  def action12; "test action12" end
  def action13; "test action13" end
  def action14; "test action14" end
  def action15; "test action15" end
  def action16; "test action16" end
  def action17; "test action17" end
  def action18; "test action18" end
  def action19; "test action19" end
  def action20; "test action20" end
  def action21; "test action21" end
  def action22; "test action22" end
  def action23; "test action23" end

  def action7
    provides :js, :css, :html, :xml, :jpg
    case params[:format]
    when "css"
      "CSS"
    when "js"
      "JS"
    when "html"
      "HTML"
    when "xml"
      "XML"
    when "jpg"
      "JPG"
    else
      raise "BAD FORMAT: #{params[:format].inspect}"
    end
  end

  def empty_id?; params[:id].empty? end

  def non_empty_id?; !empty_id? end
end
