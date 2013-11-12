_.extend Template['item-detail-form'], do ->
  accountIndex = 0
  itemName = -> Router.getData().itemName
  item = ->
    ItemCollection.findOne name: itemName()
  accountIndexDep = new Deps.Dependency

  users = ->
    fetchAll()
    currentScenario.getUsers item()
  payers = ->
    fetchAll()
    for p in currentScenario.getPaymentsForItem item()
      p.fromAccount
  account = ->
    accountIndexDep.depend()
    fetchAccounts()[accountIndex]

  created: ->
    accountIndex = 0
  item: item
  users: users
  payers: payers
  boths: -> _.intersection users(), payers()
  nothings: -> _(fetchAccounts()).difference users(), payers()
  account: account
  events: do ->
    accountEvent = (fn) ->
      (e) ->
        e.stopPropagation?()
        fn.call(this)
        if accountIndex < AccountCollection.find({}).count()
          accountIndexDep.changed()
          accountIndex++

    'click [data-both-drop-zone]': accountEvent ->
      account()?.paysAndUses item()
    'click [data-use-drop-zone]': accountEvent ->
      account()?.uses item()
    'click [data-pay-drop-zone]': accountEvent ->
      account()?.pays item()
    'click [data-nothing-drop-zone]': accountEvent ->
      
