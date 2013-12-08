_.extend Template['report-payment-detail'], do ->
  payment = ->
    Router.getData().payment

  payment: payment
  fromAccount: ->
    AccountCollection.findOne(payment().fromAccount)
  toAccount: ->
    AccountCollection.findOne(payment().toAccount)
  items: ->
    for item in payment().addItems
      ItemCollection.findOne(item)





   
    
