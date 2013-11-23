
_.extend Template['results'],
  created: ->
    Session.set 'message', ''
    currentScenario.addInternalPayments()
    currentScenario.simplifyPayments() 
  message: -> Session.get 'message'
  externalPayments: ->
    for payment in currentScenario._payments(settled: true).fetch()
      payment = new finances.Payment payment
      payment.vivifyAssociates()
  unsettledPayments: ->
    for payment in currentScenario._payments(settled: false).fetch()
      payment = new finances.Payment payment
      payment.vivifyAssociates()
  usages: ->
    for usage in currentScenario._usages().fetch()
      usage = new finances.Usage usage
      usage.vivifyAssociates()
  accounts: -> 
    currentScenario._accounts()
      
