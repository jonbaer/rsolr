raise "JRuby Required" unless defined?(JRUBY_VERSION)

require 'java'

#
# Connection for JRuby + DirectSolrConnection
#
class Solr::Connection::Adapter::Direct
  
  include Solr::Connection::Adapter::Helpers
  
  attr_accessor :opts, :connection, :home_dir
  
  # required: opts[:home_dir] is absolute path to solr home (the directory with "data", "config" etc.)
  # opts must also contain either
  #   :dist_dir => 'absolute path to solr distribution root
  # or
  #   :jar_paths => ['array of directories containing the solr lib/jars']
  # OTHER OPTS:
  #   :select_path => 'the/select/handler'
  #   :update_path => 'the/update/handler'
  # If a block is given, the @connection instance (DirectSolrConnection) is yielded
  def initialize(opts, &block)
    @home_dir = opts[:home_dir]
    opts[:data_dir] ||= File.join(@home_dir , 'data')
    if opts[:dist_dir]
      # add the standard lib and dist directories to the :jar_paths
      opts[:jar_paths] = [File.join(opts[:dist_dir], 'lib'), File.join(opts[:dist_dir], 'dist')]
    end
    @opts = default_options.merge(opts)
    require_jars(@opts[:jar_paths])
    import_dependencies
    @connection = DirectSolrConnection.new(@home_dir, @opts[:data_dir], nil)
    yield @connection if block_given?
  end
  
  # send a request to the connection
  # request '/update', :wt=>:xml, '</commit>'
  def send_request(request_url_path, params={}, data=nil)
    data = data.to_xml if data.respond_to?(:to_xml)
    full_path = build_url(request_url_path, params)
    begin
      @connection.request(full_path, data)
    rescue
      raise Solr::Connection::Adapter::RequestError.new($!.message)
    end
  end
  
  protected
  
  # do the java import thingy
  def import_dependencies
    import org.apache.solr.servlet.DirectSolrConnection
  end
  
  # require the jar files
  def require_jars(paths)
    paths = [paths] unless paths.is_a?(Array)
    paths.each do |path|
      jar_pattern = File.join(path,"**", "*.jar")
      Dir[jar_pattern].each {|jar_file| require jar_file}
    end
  end
  
end