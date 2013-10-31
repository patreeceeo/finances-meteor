describe "finances", ->
  [a1, a2, a3, i1, i2, i3] = (null for i in [1..6])
  beforeEach ->
    finances.reset()
    a1 = new finances.Account 'Fred'
    a2 = new finances.Account 'Dafny'
    a3 = new finances.Account 'Shaggy/Scooby'
    i1 = new finances.Item 'dinner', 60
    i2 = new finances.Item 'costume', 25
    i3 = new finances.Item 'snacks', 12

  it 'should be groovy', ->
    expect(finances).toBeDefined()

  it 'should track users', ->
    a1.uses i1
    a2.uses i1
    expect(a1 in finances.getUsers(i1)).toBe true
    expect(a2 in finances.getUsers(i1)).toBe true

  it 'should track payments', ->
    a1.pays i1, 50
    a2.pays i1, 50
    accounts = (p.fromAccount for p in finances.getPaymentsForItem(i1))
    expect(a1 in accounts)
    expect(a2 in accounts)

  describe 'simplifying payment graphs without cycles', ->
    beforeEach ->
      a1.paysAndUses i1
      a2.pays i2
      a3.paysAndUses i3

      a1.uses i2
      a2.uses i1
      a3.uses i1

      finances.createInternalPayments()
      finances.simplifyPayments()

    it 'should say Fred owes 25 for the costume', ->
      expect(a1.owes().total).toBe 25

    it 'should say Dafny owes 1/3 of 60 for dinner', ->
      expect(a2.owes().total).toBe 60 / 3

    it 'should say Shaggy/Scooby owe 1/3 of 60 for dinner', ->
      expect(a3.owes().total).toBe 60 / 3

  it 'should know how much each account owes (w/ cycles)', ->
    a1.uses i1
    a2.pays i1
    a2.uses i2
    a3.pays i2
    a3.uses i3
    a1.pays i3

    finances.createInternalPayments()
    finances.simplifyPayments()

    expect(a1.owes().total + a2.owes().total + a3.owes().total).toBe 0
