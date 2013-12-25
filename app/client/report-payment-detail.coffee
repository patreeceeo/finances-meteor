_.extend Template['report-payment-detail'], do ->
  payment = ->
    Router.getData().payment

  payment: payment
  fromAccount: ->
    AccountCollection.findOne(payment().fromAccount)
  toAccount: ->
    AccountCollection.findOne(payment().toAccount)
  addItems: ->
    for itemId in payment().addItems or []
      _id: itemId
      amount: UsageCollection.findOne(item: itemId, fromAccount: payment().fromAccount).amount
      name: ItemCollection.findOne(itemId).name
  minusItems: ->
    for itemId in payment().minusItems or []
      _id: itemId
      amount: UsageCollection.findOne(item: itemId, fromAccount: payment().fromAccount).amount
      name: ItemCollection.findOne(itemId).name





   
    
