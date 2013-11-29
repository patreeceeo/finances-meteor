
_.extend Template['report'],
  created: ->
    Session.set 'message', ''
    Meteor.call 'removePayments', 
      settled: false,
      (error, result) ->
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
    for account in currentScenario._accounts().fetch()
      account.incomingPayments = currentScenario._payments(toAccount: account._id).fetch()
      account.incomingTotal = 0 
      for payment in account.incomingPayments
        account.incomingTotal += payment.amount
        payment.name = (
          for item in payment.items
            currentScenario._item(item).name
        ).join('/')
      account.outgoingPayments = currentScenario._payments(fromAccount: account._id).fetch()
      account.outgoingTotal = 0 
      for payment in account.outgoingPayments
        account.outgoingTotal += payment.amount
        payment.name = (
          for item in payment.items
            currentScenario._item(item).name
        ).join('/')
      account.netTotal = account.outgoingTotal - account.incomingTotal
      account
      
