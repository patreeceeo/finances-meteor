_.extend Template['item-detail-form'], do ->
  accountIndex = 0
  itemName = -> Router.getData().itemName
  item = ->
    ItemCollection.findOne name: itemName()
  accountIndexDep = new Deps.Dependency

  users = ->
    currentScenario.findUsers item().toJSON()
  payers = ->
    payments = PaymentCollection.find(item: item().toJSON()).fetch()
    for p in payments
      AccountCollection.findOne(p.fromAccount)
  account = ->
    accountIndexDep.depend()
    fetchAccounts()[accountIndex]

  created: ->
    accountIndex = 0
    Session.set 'message', ""
  message: -> Session.get 'message'
  item: item
  users: users
  payers: payers
  boths: -> _.intersection users(), payers()
  nothings: -> 
    accounts = AccountCollection.find().fetch()
    _(accounts).reject (a) ->
      _(users()).findWhere({name: a.name})? and
      _(payers()).findWhere({name: a.name})?
  account: account
  events: do ->
    accountEvent = (fn) ->
      (e) ->
        e.stopPropagation?()
        fn.call(this)
        if accountIndex < AccountCollection.find().count()
          accountIndexDep.changed()
          accountIndex++

    'click [data-use-drop-zone]': accountEvent ->
      if not UsageCollection.findOne(
          item: item().toJSON()
          fromAccount: account().toJSON())?
        account()?.uses item()
    'click [data-pay-drop-zone]': accountEvent ->
      if not PaymentCollection.findOne(item: item().toJSON())?
        account()?.pays item()
    'click [data-nothing-drop-zone]': accountEvent ->
      
