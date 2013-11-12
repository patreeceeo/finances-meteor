
_.extend Template['results'],
  externalPayments: ->
    AccountCollection.find(
      settled: true
      toAccount: undefined
    ).fetch()
  unsettledPayments: ->
    AccountCollection.find(settled: false).fetch()
  accounts: -> fetchAccounts()
      
