
_.extend Template['results'],
  created: ->
    Session.set 'message', ''
    Meteor.call 'removePayments', 
      settled: false,
      (error, result) ->
        currentScenario.addInternalPayments()
        currentScenario.simplifyPayments() 
  message: -> Session.get 'message'
  externalPayments: ->
    scenarioDep.depend()
    for payment in currentScenario._payments(settled: true).fetch()
      payment = new finances.Payment payment
      payment.vivifyAssociates()
  unsettledPayments: ->
    scenarioDep.depend()
    for payment in currentScenario._payments(settled: false).fetch()
      payment = new finances.Payment payment
      payment.vivifyAssociates()
  usages: ->
    scenarioDep.depend()
    for usage in currentScenario._usages().fetch()
      usage = new finances.Usage usage
      usage.vivifyAssociates()
  accounts: -> 
    scenarioDep.depend()
    currentScenario._accounts()
      
