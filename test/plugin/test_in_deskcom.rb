require 'helper'

class DeskcomInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    subdomain           SUBDOMAIN
    consumer_key        CONSUMER_KEY
    consumer_secret     CONSUMER_SECRET
    oauth_token         OAUTH_TOKEN
    oauth_token_secret  OAUTH_TOKEN_SECRET
    store_file          /tmp/pos.yml
    output_format       simple
    input_api           cases
    tag                 deskcom.cases
  ]

  def create_driver(conf=CONFIG, tag='test', use_v1=false)
    Fluent::Test::InputTestDriver.new(Fluent::DeskcomInput).configure(conf, use_v1)
  end

  def test_configure
    d = create_driver

    assert_equal 'SUBDOMAIN',           d.instance.subdomain
    assert_equal 'CONSUMER_KEY',        d.instance.consumer_key
    assert_equal 'CONSUMER_SECRET',     d.instance.consumer_secret
    assert_equal 'OAUTH_TOKEN',         d.instance.oauth_token
    assert_equal 'OAUTH_TOKEN_SECRET',  d.instance.oauth_token_secret
    assert_equal '/tmp/pos.yml',        d.instance.store_file
    assert_equal 'simple',              d.instance.output_format
    assert_equal 'cases',               d.instance.input_api
    assert_equal 'deskcom.cases',       d.instance.tag
  end

  def test_get_content
    # TO DO: write actual code
  end
end