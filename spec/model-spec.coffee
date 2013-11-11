describe 'the example data', ->

  beforeEach ->
    AccountCollection.remove {}
    ItemCollection.remove {}
    PaymentCollection.remove {}
    AccountCollection.insert example for example in [
      { name: 'dude' }
      { name: 'walter' }
    ]
    ItemCollection.insert example for example in [
      { name: 'ball', amount: 6 }
      { name: 'whiterussian', amount: 6 }
    ]
    PaymentCollection.insert example for example in [
      {
        fromAccount:
          name: 'dude'
        item:
          name: 'ball'
      }
      {
        fromAccount:
          name: 'walter'
        item:
          name: 'whiterussian'
      }
    ]

  describe 'account collection', ->

    it 'should have >0 accounts', ->
      expect(AccountCollection.find({}).count()).toBeGreaterThan 0

    it 'should return Account objects', ->
      expect(
        AccountCollection.find({})
          .fetch()[0].constructor
      ).toBe finances.Account
      expect(_.values(currentScenario.accounts).length).toBeGreaterThan 0

  describe 'item collection', ->

    it 'should have >0 items', ->
      expect(ItemCollection.find({}).count()).toBeGreaterThan 0

    it 'should return Item objects', ->
      expect(
        ItemCollection.find({})
          .fetch()[0].constructor
      ).toBe finances.Item
      expect(_.values(currentScenario.items).length).toBeGreaterThan 0

  describe 'payment collection', ->

    it 'should have >0 items', ->
      expect(PaymentCollection.find({}).count()).toBeGreaterThan 0

    it 'should return Payment objects', ->
      expect(
        PaymentCollection.find({})
          .fetch()[0].constructor
      ).toBe finances.Payment
      expect(currentScenario.payments.length).toBeGreaterThan 0

      
