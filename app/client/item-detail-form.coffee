_.extend Template['item-detail-form'], do ->
  itemId = ->
    Router.getData().itemId
  item = ->
    currentScenario._item itemId()

  users = ->
    users = []
    currentScenario._usages(item: itemId()).forEach (usage) =>
      user = currentScenario._account(usage.fromAccount)
      user.usage = usage._id
      users.push(user) if user?
    users
  payers = ->
    accounts = []
    currentScenario._payments(items: itemId(), settled: true).forEach (payment) ->
      account = currentScenario._account(payment.fromAccount)
      account.payment = payment._id
      accounts.push(account) if account?
    accounts 

  created: ->
    accountIndex = 0
    Session.set 'message', ""
  message: -> Session.get 'message'
  item: item
  accounts: ->
    for account in currentScenario._accounts().fetch()
      debugger
      account.pays = currentScenario._payment(fromAccount: account._id, items: item()._id)?
      account.uses = currentScenario._usage(fromAccount: account._id, item: item()._id)?
      account

  events: do ->
    'click input[type=checkbox]': (e) ->
      $el = $(e.target)
      checked = $el.prop 'checked'
      account = new finances.Account currentScenario._account($el.data 'account')
      action = $el.data 'action'
      if checked
        if action is 'pays'
          account.pays item()
        else
          account.uses item()
      else
        debugger
        if action is 'pays'
          payment = currentScenario._payment fromAccount: account._id, items: item()._id
          PaymentCollection.remove payment?._id
        if action is 'uses'
          usage = currentScenario._usage fromAccount: account._id, item: item()._id
          UsageCollection.remove usage?._id
    'click [data-remove-button][data-usage]': (e) ->
      currentScenario.removeUsage $(e.target).data().usage
    'click [data-remove-button][data-payment]': (e) ->
      currentScenario.removePayment $(e.target).data().payment 
