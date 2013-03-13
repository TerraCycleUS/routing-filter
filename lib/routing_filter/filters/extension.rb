# The Extension filter chops a file extension off from the end of the
# recognized path. When a path is generated the filter re-adds the extension 
# to the path accordingly.
# 
#   incoming url: /products.xml
#   filtered url: /products
#   generated url: /products.xml
# 
# You can install the filter like this:
#
#   # in config/routes.rb
#   Rails.application.routes.draw do
#     filter :extension
#   end

module RoutingFilter
  class Extension < Filter
    attr_reader :extension, :exclude, :exclude_host

    def initialize(*args)
      super
      @exclude      = options[:exclude]
      @exclude_host = options[:exclude_host]
      @extension    = options[:extension] || 'html'
    end

    def around_recognize(path, env, &block)
      host = env['HTTP_HOST'].present? ? env['HTTP_HOST'] : 'www.example.com'
      extract_extension!(path) unless excluded?(path, host)
      yield
    end

    def around_generate(params, &block)
      yield.tap do |result|
        url = result.is_a?(Array) ? result.first : result
        append_extension!(url) if append_extension?(url)
      end
    end

    protected
    
      def extract_extension!(path)
        path.sub!(/\.#{extension}$/, '')
        $1
      end
      
      def append_extension?(url)
        !(blank?(url) || excluded?(url) || mime_extension?(url))
      end
      
      def append_extension!(url)
        url.replace url.sub(/(\?|$)/, ".#{extension}\\1")
      end
      
      def blank?(url)
        url.blank? || !!url.match(%r(^/(\?|$)))
      end
      
      def excluded?(path, host = 'www.example.com')
        return true if case exclude
        when Regexp
          path =~ exclude
        when Proc
          exclude.call(path)
        end

        case exclude_host
        when Regexp
          host =~ exclude_host
        when Proc
          exclude_host.call(host)
        end
      end
      
      def mime_extension?(url)
        url =~ /\.#{Mime::EXTENSION_LOOKUP.keys.join('|')}(\?|$)/
      end
  end
end
