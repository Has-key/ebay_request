class EbayRequest::Base
  def initialize(options = {})
    @options = options
    @options[:timeout] ||= EbayRequest.config.timeout
  end

  attr_reader :options

  def response(callname, payload)
    EbayRequest.config.validate!
    request(URI.parse(endpoint_with_sandbox), callname, payload)
  end

  protected

  def endpoint
    raise NotImplementedError, "Implement #{self.class.name}#endpoint"
  end

  def ns
    "urn:ebay:apis:eBLBaseComponents"
  end

  def headers(_)
    {}
  end

  def payload(_, _)
    {}
  end

  private

  def endpoint_with_sandbox
    endpoint % { sandbox: EbayRequest.config.sandbox? ? ".sandbox" : "" }
  end

  def request(url, callname, request)
    h = headers(callname)
    b = payload(callname, request).to_json
    http = prepare(url)

    post = Net::HTTP::Post.new(url.path, h)
    post.body = b

    response = http.start { |r| r.request(post) }.body

    EbayRequest.log(url, h, b, response)

    JSON.parse(response)
  end

  def prepare(url)
    Net::HTTP.new(url.host, url.port).tap do |http|
      http.read_timeout = options[:timeout]

      if url.port == 443
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end
  end
end
