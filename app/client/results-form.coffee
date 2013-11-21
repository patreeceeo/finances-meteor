
_.extend Template['results'],
  created: ->
    Meteor.call 'removeUnsettledPayments'
    currentScenario.createInternalPayments()
    currentScenario.simplifyPayments()
  externalPayments: ->
    all = PaymentCollection.find().fetch()
    _(all).filter (p) -> not p.toAccount?
  unsettledPayments: ->
    PaymentCollection.find(settled: false)
  usages: ->
    UsageCollection.find()
  accounts: -> 
    AccountCollection.find()
      
