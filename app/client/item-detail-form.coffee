_.extend Template['item-detail-form'], do ->
  item = ->
    Router.getData().item

  users = ->
    users = []
    currentScenario._usages(item: item()._id).forEach (usage) =>
      user = currentScenario._account(usage.fromAccount)
      user.usage = usage._id
      users.push(user) if user?
    users
  payers = ->
    accounts = []
    currentScenario._payments(items: item()._id, settled: true).forEach (payment) ->
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
      payment = currentScenario._payment(fromAccount: account._id, items: item()._id, settled: true)
      account.pays = payment?

      usage = currentScenario._usage(fromAccount: account._id, item: item()._id)
      account.uses = usage?

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
        if action is 'pays'
          Meteor.call 'removePayments', fromAccount: account._id, items: item()._id, settled: true
        if action is 'uses'
          Meteor.call 'removeUsages', fromAccount: account._id, item: item()._id
    'click [data-remove-button][data-usage]': (e) ->
      currentScenario.removeUsage $(e.target).data().usage
    'click [data-remove-button][data-payment]': (e) ->
      currentScenario.removePayment $(e.target).data().payment 
