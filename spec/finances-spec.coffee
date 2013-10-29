describe "finances", ->

  beforeEach ->
    finances.reset()

  it 'should be groovy', ->
    expect(finances).toBeDefined()

  it 'should track users', ->
    a1 = new finances.Account 'Fred'
    a2 = new finances.Account 'Dafny'
    i1 = new finances.Item 'dinner', 80
    a1.uses i1
    a2.uses i1
    expect(a1 in finances.getUsers(i1)).toBe true
    expect(a2 in finances.getUsers(i1)).toBe true

  it 'should track payments', ->
    a1 = new finances.Account 'Fred'
    a2 = new finances.Account 'Dafny'
    i1 = new finances.Item 'dinner', 80
    a1.pays i1, 50
    a2.pays i1, 50
    accounts = p.account for p in finances.getPayments(i1)
    expect(a1 in accounts)
    expect(a2 in accounts)




