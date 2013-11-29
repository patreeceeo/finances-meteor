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
      user.usage = usage._id
      users.push(user) if user?
    users
  payers = ->
    accounts = []
    currentScenario._payments(items: itemId()).forEach (payment) ->
      account = currentScenario._account(payment.fromAccount)
      account.payment = payment._id
      accounts.push(account) if account?
    accounts 
  account = ->
    accountIndexDep.depend()
    accounts = currentScenario._accounts().fetch()
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
        accountIndex++
        if accountIndex >= currentScenario._accounts().count()
          accountIndex = 0
          itemIds = currentScenario._items().map (item) ->
            item._id
          index = _(itemIds).indexOf(itemId()) + 1
          if index >= itemIds.length
            index = 0
          Router.go 'item-detail-form', 
            _id: itemIds[index]
            scenario: currentScenario._id
        accountIndexDep.changed()


    'click [data-use-drop-zone]': accountEvent ->
      if not currentScenario._usage(
          item: itemId()
          fromAccount: account()._id)?
        account()?.uses item()
    'click [data-pay-drop-zone]': accountEvent ->
      if not currentScenario._payment(items: itemId())?
        account()?.pays item()
    'click [data-both-drop-zone]': accountEvent ->
      if not currentScenario._payment(items: itemId())?
        account()?.paysAndUses item()
    'click [data-nothing-drop-zone]': accountEvent ->
    'click [data-remove-button][data-usage]': (e) ->
      currentScenario.removeUsage $(e.target).data().usage
    'click [data-remove-button][data-payment]': (e) ->
      currentScenario.removePayment $(e.target).data().payment 
