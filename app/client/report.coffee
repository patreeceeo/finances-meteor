
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
    for payment in PaymentCollection.find(settled: true).fetch()
      payment = new finances.Payment payment
      payment.vivifyAssociates()
  unsettledPayments: ->
    for payment in PaymentCollection.find(settled: false).fetch()
      payment = new finances.Payment payment
      payment.vivifyAssociates()
  accounts: -> 
    s = currentScenario

    for account in s._accounts().fetch()
      _.extend account,
        balance: 0
        fairShare: 0
        incomingPayments: []
        outgoingPayments: []
        usages: []

      for payment in s._payments(fromAccount: account._id).fetch()
        account.balance -= payment.amount
        payment = new finances.Payment(payment).vivifyAssociates()
        payment.itemNames = finances.buildArithmaticExpression(payment.addItems, payment.minusItems)
        account.outgoingPayments.push payment

      for payment in s._payments(toAccount: account._id).fetch()
        account.balance += payment.amount
        payment = new finances.Payment(payment).vivifyAssociates()
        payment.itemNames = finances.buildArithmaticExpression(payment.addItems, payment.minusItems)
        account.incomingPayments.push payment

      for usage in s._usages(fromAccount: account._id).fetch()
        itemAmount = s._item(usage.item).amount
        nUsers = s._usages(item: usage.item).count()
        account.fairShare += itemAmount / nUsers
        usage.item = s._item usage.item
        account.usages.push usage
      
      account
      
