_.extend Template['item-detail-form'], do ->
  item = ->
    Router.getData().item

  users = ->
    users = []
    UsageCollection.find(item: item()._id).forEach (usage) =>
      user = AccountCollection.findOne(usage.fromAccount)
      user.usage = usage._id
      users.push(user) if user?
    users
  payers = ->
    accounts = []
    PaymentCollection.find(addItems: item()._id, settled: true).forEach (payment) ->
      account = AccountCollection.findOne(payment.fromAccount)
      account.payment = payment._id
      accounts.push(account) if account?
    accounts 

  created: ->
    accountIndex = 0
    Session.set 'message', ""
  message: -> Session.get 'message'
  item: item
  accounts: ->
    for account in AccountCollection.find().fetch()
      payment = PaymentCollection.findOne(fromAccount: account._id, addItems: item()._id, settled: true)
      account.pays = payment?

      usage = UsageCollection.findOne(fromAccount: account._id, item: item()._id)
      account.uses = usage?

      account

  events: do ->
    'click input[type=checkbox]': (e) ->
      $el = $(e.target)
      checked = $el.prop 'checked'
      account = new finances.Account AccountCollection.findOne($el.data 'account')
      action = $el.data 'action'
      if checked
        if action is 'pays'
          account.pays item()
        else
          account.uses item()
      else
        if action is 'pays'
          Meteor.call 'removePayments', fromAccount: account._id, addItems: item()._id, settled: true
        if action is 'uses'
          Meteor.call 'removeUsages', fromAccount: account._id, item: item()._id
