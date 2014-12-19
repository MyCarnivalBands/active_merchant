require 'test_helper'

class RemoteTest < Test::Unit::TestCase
  def setup
    @gateway = QuickbooksGateway.new(fixtures(:quickbooks))
    @amount = 1.00
    @credit_card = credit_card('4000100011112224')
    @declined_card = credit_card('4000000000000002')

    @options = {
      order_id: '1',
      billing_address: address({ zip: 90210, 
                                 country: 'US', 
                                 state: 'CA'}),
      description: 'Store Purchase'
    }
  end

  def test_successful_purchase
    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal 'Transaction Approved', response.message
  end

  def test_failed_purchase
    response = @gateway.purchase(@amount, @declined_card, @options)
    assert_failure response
    assert_equal "cardNumber is invalid.", response.message
  end

  def test_successful_authorize_and_capture
    auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth

    assert capture = @gateway.capture(nil, auth.authorization)
    assert_success capture
  end

  def test_failed_authorize
    response = @gateway.authorize(@amount, @declined_card, @options)
    assert_failure response
  end

  def test_partial_capture
    auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth

    assert capture = @gateway.capture(@amount-1, auth.authorization)
    assert_success capture
  end

  def test_failed_capture
    response = @gateway.capture(nil, '')
    assert_failure response
  end

  def test_successful_refund
    purchase = @gateway.purchase(@amount, @credit_card, @options)
    assert_success purchase

    assert refund = @gateway.refund(nil, purchase.authorization)
    assert_success refund
  end

  def test_partial_refund
    purchase = @gateway.purchase(@amount, @credit_card, @options)
    assert_success purchase

    assert refund = @gateway.refund(@amount-1, purchase.authorization)
    assert_success refund
  end

  def test_failed_refund
    response = @gateway.refund(nil, '')
    assert_failure response
  end

  def test_successful_void
    auth = @gateway.authorize(@amount, @credit_card, @options)
    assert_success auth
    assert void = @gateway.void(auth.authorization)
    assert_success void
  end

  def test_failed_void
    response = @gateway.void('')
    assert_failure response
  end

  def test_successful_verify
    response = @gateway.verify(@credit_card, @options)
    assert_success response
    assert_match %r{REPLACE WITH SUCCESS MESSAGE}, response.message
  end

  def test_failed_verify
    response = @gateway.verify(@declined_card, @options)
    assert_failure response
    assert_match %r{REPLACE WITH FAILED PURCHASE MESSAGE}, response.message
    assert_equal Gateway::STANDARD_ERROR_CODE[:card_declined], response.error_code
  end

  def test_invalid_login
    gateway = QuickbooksGateway.new(
      consumer_key: '',
      consumer_secret: '',
      access_token: '',
      token_secret: '',
      realm: ''
    )
    response = gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
  end

  def test_dump_transcript
    skip('See quickbooks_test.rb for a scrubbed transcript')
    dump_transcript_and_fail(@gateway, @amount, @credit_card, @options)
  end
end
