module PinPayment
  class Customer < Base
    attr_accessor :token,  :email,  :created_at,  :card
    protected     :token=, :email=, :created_at=, :card=

    # Uses the pin API to create a customer.
    #
    # @param [String] email the customer's email address
    # @param [String, PinPayment::Card, Hash] card_or_token the customer's credit card details
    # @return [PinPayment::Customer]
    def self.create email, card_or_token = nil
      attributes = self.attributes - [:token, :created_at]
      options    = parse_options_for_request(attributes, email: email, card: card_or_token)
      response   = post(URI.parse(PinPayment.api_url).tap{|uri| uri.path = '/1/customers' }, options)
      new(response.delete('token'), response)
    end
    
    def self.delete_customer(token)
    	delete(URI.parse(PinPayment.api_url).tap{|uri| uri.path = "/1/customers/#{token}" })
    end

    # Update a customer using the pin API.
    #
    # @param [String] token the customer token
    # @param [String] email the customer's new email address
    # @param [String, PinPayment::Card, Hash] card_or_token the customer's new credit card details
    # @return [PinPayment::Customer]
    def self.update token, email, card_or_token = nil
      new(token).tap{|c| c.update(email, card_or_token) }
    end

    # Fetches a customer's credit cards using the pin API.
    #
    # @param [String] token the customer token
    # @return [PinPayment::Card]
    def self.find_cards token
      response = get(URI.parse(PinPayment.api_url).tap { |uri| uri.path = "/1/customers/#{token}/cards" })
      response.map { |x| PinPayment::Card.new(x.delete('token'), x) }
    end

    # Fetches a customer using the pin API.
    #
    # @param [String] token the customer token
    # @return [PinPayment::Customer]
    def self.find token
      response = get(URI.parse(PinPayment.api_url).tap{|uri| uri.path = "/1/customers/#{token}" })
      new(response.delete('token'), response)
    end

    # Fetches all of your customers using the pin API.
    #
    # @return [Array<PinPayment::Customer>]
    # TODO: pagination
    def self.all
      response = get(URI.parse(PinPayment.api_url).tap{|uri| uri.path = '/1/customers' })
      response.map{|x| new(x.delete('token'), x) }
    end


    # Adds a card to a customer using the pin API.
    #
    # @param [String] token of the customer
    # @param [String, PinPayment::Card, Hash] card_token the customer's new credit card details
    # @return [PinPayment::Card]
    def self.add_card customer_token, card_token = nil
      attributes = [:card_token]
      options    = parse_options_for_request(attributes, card_token: card_token)
      response   = post(URI.parse(PinPayment.api_url).tap{|uri| uri.path = "/1/customers/#{customer_token}/cards" }, options)
      PinPayment::Card.new(response['token'], response)
    end

    # Adds a card to a customer using the pin API.
    #
    # @param [String] token of the customer
    # @param [String, PinPayment::Card, Hash] card_token the customer's new credit card details
    # @return [PinPayment::Card]
    def self.remove_card customer_token, card_token = nil
      delete(URI.parse(PinPayment.api_url).tap{|uri| uri.path = "/1/customers/#{customer_token}/cards/#{card_token}" }, { skip_json_parsing: true })
    end

    # Update a customer using the pin API.
    #
    # @param [String] email the customer's new email address
    # @param [String, PinPayment::Card, Hash] card_or_token the customer's new credit card details
    # @return [PinPayment::Customer]
    def update email, card_or_token = nil
      attributes = self.class.attributes - [:token, :created_at]
      options    = self.class.parse_options_for_request(attributes, email: email, card: card_or_token)
      response   = self.class.put(URI.parse(PinPayment.api_url).tap{|uri| uri.path = "/1/customers/#{token}" }, options)
      self.email = response['email']
      self.card  = response['card']
      self
    end

    protected

    def self.attributes
      [:token, :email, :created_at, :card]
    end

  end
end
