
_.extend Template['results'],
  created: ->
    Session.set 'message', ''
    Meteor.call 'removeUnsettledPayments'
    currentScenario.createInternalPayments()
    currentScenario.simplifyPayments() 
  message: -> Session.get 'message'
  externalPayments: ->
    all = PaymentCollection.find().fetch()
    _(all).filter (p) -> not p.toAccount?
  unsettledPayments: ->
    PaymentCollection.find(settled: false)
  usages: ->
    UsageCollection.find()
  accounts: -> 
    AccountCollection.find()
      
