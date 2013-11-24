root = this

Array::where = (object) ->
  _(this).where(object)

Array::contains = (object) ->
  @where(object).length > 0


describe "finances", ->
  [s, a1, a2, a3, i1, i2, i3] = (null for i in [1..7])

  beforeEach ->
    root.ScenarioCollection = new Meteor.Collection null
    root.AccountCollection = new Meteor.Collection null
    root.ItemCollection = new Meteor.Collection null
    root.PaymentCollection = new Meteor.Collection null
    root.UsageCollection = new Meteor.Collection null
    s = new finances.Scenario name: 'test' 
    s._id = ScenarioCollection.insert s
    a1 = s.addAccount name: 'Fred'
    a2 = s.addAccount name: 'Dafny'
    a3 = s.addAccount name: 'Shaggy/Scooby'
    i1 = s.addItem name: 'dinner', amount: 60
    i2 = s.addItem name: 'costume', amount: 25
    i3 = s.addItem name: 'snacks', amount: 12

  it 'should be groovy', ->
    expect(finances).toBeDefined()

  it 'should track users', ->
    a1.uses i1
    a2.uses i1
    s._usages(item: i1._id).forEach (usage) =>
      expect(usage.fromAccount in [a1._id, a2._id]).toBeTruthy()

  it 'should track payments', ->
    a1.pays i1, 50
    a2.pays i1, 50
    expect(s._payment(items: i1._id, fromAccount: a1._id)).toBeDefined()
    expect(s._payment(items: i1._id, fromAccount: a2._id)).toBeDefined()

  describe 'when settling debts', ->

    it 'should ignore equal and opposite debts', ->
      i2 = i1.clone 'b-fast'
      a1.paysAndUses i1
      a2.paysAndUses i2
      a1.uses i2
      a2.uses i1

      s.addInternalPayments()
      s.simplifyPayments()

      expect(a1.crunch().total).toBe 0
      expect(a2.crunch().total).toBe 0

    it 'should properly handle this scenario', ->
      i1 = s.addItem amount: 6, name: 'i1'
      i2 = s.addItem amount: 12, name: 'i2'
      a1.paysAndUses i1
      a2.uses i1
      a1.uses i2
      a2.paysAndUses i2

      s.addInternalPayments()
      s.simplifyPayments()

      expect(a1.crunch().total).toBe 12 / 2 - 6 / 2
      expect(a2.crunch().total).toBe 0

    it 'should ignore debts to and from the same Account', ->
      a1.paysAndUses i1

      s.addInternalPayments()
      s.simplifyPayments()

      expect(a1.crunch().total).toBe 0

    it 'should ignore larger cycles of equal debts', ->
      i2 = i1.clone('b-fast')
      i3 = i1.clone('lunch')
      a1.paysAndUses i1
      a2.uses i1
      a2.paysAndUses i2
      a3.uses i2
      a3.paysAndUses i3
      a1.uses i3

      s.addInternalPayments()
      s.simplifyPayments()

      expect(a1.crunch().total).toBe 0
      expect(a2.crunch().total).toBe 0
      expect(a3.crunch().total).toBe 0

    it 'should replace debts along the same path with one direct debt', ->
      i2 = i1.clone('b-fast')

      a1.paysAndUses i1
      a2.uses i1
      a2.paysAndUses i2
      a3.uses i2

      s.addInternalPayments()
      s.simplifyPayments()

      expect(a3.crunch().total).toBe i2.amount / 2
      expect(a2.crunch().total).toBe 0
      expect(a1.crunch().total).toBe 0

    describe 'when all debts are not equal', ->

      describe 'when the first debt in the path is bigger', ->

        it 'should reduce debts along a given path and add a direct debt', ->

          i2 = s.addItem 
            name: 'dessert'
            amount: i1.amount + 5

          a1.paysAndUses i1
          a2.uses i1
          a2.paysAndUses i2
          a3.uses i2

          s.addInternalPayments()
          s.simplifyPayments()

          expect(a3.crunch().total).toBe i2.amount / 2
          expect(a2.crunch().total).toBe 0
          expect(a1.crunch().total).toBe 0

      describe 'when the second debt in the path is bigger', ->

        it 'should reduce debts along a given path and add a direct debt', ->
          i2 = s.addItem
            name: 'dessert'
            amount: i1.amount + 5

          a1.paysAndUses i2
          a2.uses i2
          a2.paysAndUses i1
          a3.uses i1

          s.addInternalPayments()
          s.simplifyPayments()

          expect(a3.crunch().total).toBe i1.amount / 2
          expect(a2.crunch().total).toBe i2.amount / 2 - i1.amount / 2
          expect(a1.crunch().total).toBe 0

  describe 'pseudo-random number generator', ->

    it 'should always generate the same sequence for a given seed', ->
      rng1 = finances.getPRNG(42)
      sequence1 = rng1() for i in [1..20]
      rng2 = finances.getPRNG(42)
      sequence2 = rng2() for i in [1..20]
      for i in [1..20]
        expect(sequence1[i]).toEqual sequence2[i]
  
  xdescribe 'test scenarios', ->
    # TODO: make a scenario class and move all the methods and
    #       properties of `finances` to `finances.Scenario`
    count = 10
    findSum = (list) ->
      add = (a, b) ->
        a + b
      _.reduce list, add, 0
    scenarios = []
    beforeEach ->
      results =
        for seed in [0..20]
          finances.testScenario seed, s

    it 'should have payments', ->
      for result in results
        expect(result.totalPayments).toBeGreaterThan 0

    it 'should have all items paid for', ->
      for result in results
        expect(result.totalPayments).toBe findSum (i.amount for i in result.items)
        expect(result.payments.length >= result.items.length).toBeTruthy()
        for i in result.items
          expect(findSum(
            p.amount for p in s.findPayments items: i._id
          )).toBe i.amount
        
    it 'should have every account at least either a payer or a user', ->
      for result in results
        for a in s.accounts
          expect(a.usesItems.length or a.sendsPayments.length).toBeGreaterThan 0

    it """should transform to one in which the net amount
          that each account pays is equal""", ->
      for result in results
        s.addInternalPayments()
        s.simplifyPayments()
        fairShare = s.totalPayments / s.accounts.length
        for a in s.accounts.length
          share = findSum (p.amount for p in a.sendsPayments) -
            findSum (p.amount for p in a.receivesPayments)

          expect(share).toEqual fairShare
