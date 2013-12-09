_.extend Template['report-payment-detail'], do ->
  payment = ->
    Router.getData().payment

  payment: payment
  fromAccount: ->
    AccountCollection.findOne(payment().fromAccount)
  toAccount: ->
    AccountCollection.findOne(payment().toAccount)
  addItems: ->
    for item in payment().addItems or []
      item = ItemCollection.findOne(item)
      item.nUsages = UsageCollection.find(item: item._id).count()
      item
  minusItems: ->
    for item in payment().minusItems or []
      item = ItemCollection.findOne(item)
      item.nUsages = UsageCollection.find(item: item._id).count()
      item





   
    
