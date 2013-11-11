xdescribe 'the example data', ->

  beforeEach ->
    finances.reset()

  describe 'account collection', ->

    it 'should have >0 accounts', ->
      expect(AccountCollection.find({}).count()).toBeGreaterThan 0

    it 'should return Account objects', ->
      expect(
        AccountCollection.find({})
          .fetch()[0].constructor
      ).toBe finances.Account
      expect(_.values(finances.accounts).length).toBeGreaterThan 0

  describe 'item collection', ->

    it 'should have >0 items', ->
      expect(ItemCollection.find({}).count()).toBeGreaterThan 0

    it 'should return Item objects', ->
      expect(
        ItemCollection.find({})
          .fetch()[0].constructor
      ).toBe finances.Item
      expect(_.values(finances.items).length).toBeGreaterThan 0

  describe 'payment collection', ->

    it 'should have >0 items', ->
      expect(PaymentCollection.find({}).count()).toBeGreaterThan 0

    it 'should return Payment objects', ->
      expect(
        PaymentCollection.find({})
          .fetch()[0].constructor
      ).toBe finances.Payment
      expect(finances.payments.length).toBeGreaterThan 0

      
