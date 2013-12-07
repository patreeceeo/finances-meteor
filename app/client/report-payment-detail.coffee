_.extend Template['report-payment-detail'], do ->
  payment = ->
    Router.getData().payment

  payment: payment
  fromAccount: ->
    currentScenario._account(payment().fromAccount)
  toAccount: ->
    currentScenario._account(payment().toAccount)
  items: ->
    for item in payment().items
      currentScenario._item(item)





   
    
