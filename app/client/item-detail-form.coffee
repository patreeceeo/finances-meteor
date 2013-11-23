_.extend Template['item-detail-form'], do ->
  accountIndex = 0
  itemId = ->
    Router.getData().itemId
  item = ->
    currentScenario._item itemId()
  accountIndexDep = new Deps.Dependency

  users = ->
    users = []
    currentScenario._usages(item: itemId()).forEach (usage) =>
      user = currentScenario._account(usage.fromAccount)
      users.push(user) if user?
    users
  payers = ->
    accounts = []
    currentScenario._payments(item: itemId()).forEach (payment) ->
      account = currentScenario._account(payment.fromAccount)
      accounts.push(account) if account?
    accounts 
  account = ->
    accountIndexDep.depend()
    accounts = currentScenario._accounts().fetch()
    if accounts[accountIndex]?
      new finances.Account accounts[accountIndex]

  created: ->
    accountIndex = 0
    Session.set 'message', ""
  message: -> Session.get 'message'
  item: item
  users: users
  payers: payers
  account: account
  events: do ->
    accountEvent = (fn) ->
      (e) ->
        e.stopPropagation?()
        fn.call(this)
        if accountIndex < currentScenario._accounts().count()
          accountIndex++
          accountIndexDep.changed()

    'click [data-use-drop-zone]': accountEvent ->
      if not currentScenario._usage(
          item: itemId()
          fromAccount: account()._id)?
        account()?.uses item()
    'click [data-pay-drop-zone]': accountEvent ->
      if not currentScenario._payment(item: itemId())?
        account()?.pays item()
    'click [data-nothing-drop-zone]': accountEvent ->
      
