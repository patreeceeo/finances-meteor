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
    accounts = p.account for p in finances.getPayments(i1)
    expect(a1 in accounts)
    expect(a2 in accounts)

  it 'should know how much each person (account) owes (w/o non-trivial cycles)', ->
    a1.paysAndUses i1
    a2.pays i2
    a3.paysAndUses i3

    a1.uses i2
    a2.uses i1
    a3.uses i1

    expect(a1.owes().total).toBe 25
    expect(a2.owes().total).toBe 60 / 3
    expect(a3.owes().total).toBe 60 / 3

  xit 'should know how much each person (account) owes (w/ non-trivial cycles)', ->
    a1.uses i1
    a2.pays i1
    a2.uses i2
    a3.pays i2
    a3.uses i3
    a1.pays i3

    expect(a1.owes().total + a2.owes().total + a3.owes().total).toBe 0
