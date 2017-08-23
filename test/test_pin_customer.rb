require './test_helper'

class TestPinCustomer < MiniTest::Unit::TestCase
  def setup
    common_setup
  end

  def test_create_with_blank_email
    FakeWeb.register_uri(:post, 'https://test-api.pin.net.au/1/customers', body: fixtures['responses']['customer']['blank_email'])
    assert_raises PinPayment::Error::InvalidResource do
      PinPayment::Customer.create(email: nil, card: card_hash)
    end
  end

  def test_create_success
    customer = created_customer
    assert_kind_of PinPayment::Customer, customer
  end
  
  def test_delete_success
  	customer = created_customer
    FakeWeb.register_uri(:delete, "https://test-api.pin.net.au/1/customers/#{customer.token}", body: fixtures['responses']['customer']['deleted'])
    response = PinPayment::Customer.delete_customer(customer.token)
    assert_empty response
  end
  
  def test_delete_not_found
  	token = 'none-existing-token'
    FakeWeb.register_uri(:delete, "https://test-api.pin.net.au/1/customers/#{token}", body: fixtures['responses']['customer']['delete_not_found'])
    assert_raises PinPayment::Error::ResourceNotFound do
      PinPayment::Customer.delete_customer(token)
    end
  end

  def test_direct_update
    customer = created_customer
    FakeWeb.register_uri(:put, "https://test-api.pin.net.au/1/customers/#{customer.token}", body: fixtures['responses']['customer']['updated'])
    customer = PinPayment::Customer.update(customer.token, 'changed@example.com')
    assert_equal 'changed@example.com', customer.email
  end

  def test_object_update
    customer = created_customer
    FakeWeb.register_uri(:put, "https://test-api.pin.net.au/1/customers/#{customer.token}", body: fixtures['responses']['customer']['updated'])
    customer.update('changed@example.com')
    assert_equal 'changed@example.com', customer.email
  end

  def test_find_customer
    customer = created_customer
    FakeWeb.register_uri(:get, "https://test-api.pin.net.au/1/customers/#{customer.token}", body: fixtures['responses']['customer']['created'])
    customer = PinPayment::Customer.find(customer.token)
    assert_kind_of PinPayment::Customer, customer
  end

  def test_fetch_all_customer_cards
    customer = created_customer
    FakeWeb.register_uri(:get, "https://test-api.pin.net.au/1/customers/#{customer.token}/cards", body: fixtures['responses']['customer']['cards']['all'])
    cards = PinPayment::Customer.find_cards customer.token
    assert_kind_of Array, cards
    assert_kind_of PinPayment::Card, cards.first
  end

  def test_fetch_all_customers
    FakeWeb.register_uri(:get, 'https://test-api.pin.net.au/1/customers', body: fixtures['responses']['customer']['cards']['all'])
    customers = PinPayment::Customer.all
    assert_kind_of Array, customers
    assert_kind_of PinPayment::Customer, customers.first
  end

  def test_create_customer_with_card_hash
    FakeWeb.register_uri(:post, 'https://test-api.pin.net.au/1/customers', body: fixtures['responses']['customer']['create_with_card'])
    customer = PinPayment::Customer.create('roland@pin.net.au', card_hash)
    assert_kind_of PinPayment::Card, customer.card
    assert_kind_of String, customer.card.token
    assert customer.card.token.length > 0
  end

  def test_add_card_success
    card_token = 'card_12345678910'
    customer = created_customer
    FakeWeb.register_uri(:post, "https://test-api.pin.net.au/1/customers/#{customer.token}/cards", body: fixtures['responses']['customer']['card']['added'])
    card = PinPayment::Customer.add_card(customer.token, card_token)
    assert_kind_of PinPayment::Card, card
    assert_equal card.token, 'card_23LGmaeLvHj0SM-wa_rQ7g'
    assert_equal card.display_number, 'XXXX-XXXX-XXXX-0000'
    assert_equal card.scheme, 'visa'
    assert_equal card.address_line1, 'Test'
    assert_equal card.address_line2, 'test'
    assert_equal card.address_city, 'Lathlain'
    assert_equal card.address_postcode, '6454'
    assert_equal card.address_state, 'VIC'
    assert_equal card.address_country, 'Australia'
  end

  def test_add_card_failure
    card_token = 'card_nonexisting_token'
    customer = created_customer
    FakeWeb.register_uri(:post, "https://test-api.pin.net.au/1/customers/#{customer.token}/cards", body: fixtures['responses']['customer']['card']['wrong_token_error'])
    assert_raises PinPayment::Error do
      PinPayment::Customer.add_card(customer.token, card_token)
    end
  end

  def test_remove_card_success
    card_token = 'card_existing_token'
    customer = created_customer
    FakeWeb.register_uri(:delete, "https://test-api.pin.net.au/1/customers/#{customer.token}/cards/#{card_token}", body: fixtures['responses']['customer']['card']['removed'])
    response = PinPayment::Customer.remove_card(customer.token, card_token)
    puts response
  end

  def test_remove_card_failure
    card_token = 'card_nonexisting_token'
    customer = created_customer
    FakeWeb.register_uri(:delete, "https://test-api.pin.net.au/1/customers/#{customer.token}/cards/#{card_token}", body: fixtures['responses']['customer']['card']['wrong_token_error'])
    assert_raises PinPayment::Error do
      PinPayment::Customer.remove_card(customer.token, card_token)
    end
  end
end
