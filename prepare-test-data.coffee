@prepareTestData = ->
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
