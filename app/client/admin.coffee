_.extend Template['admin-login'], do ->
  password = null
  $input = null

  rendered: ->
    $input = $ 'input[name=password]'
    $input.hide()
    Meteor.call 'getAdminCreds', (error, result) ->
      password = result.password
      $input.show()
      $input.focus()
  events:
    'keydown input[name=password]': (e) ->
      if e.keyCode is 13
        e.preventDefault()
        e.stopPropagation()
        if $input.val() is password
          Session.set 'adminUser', true
          Router.go 'admin'

_.extend Template['admin-global-menu'],
  events:
    'click a[data-logout-button]': ->
      Session.set 'adminUser', false

_.extend Template['admin'],
  scenarios: ->
    ScenarioCollection.find()
  accounts: ->
    AccountCollection.find()
  items: ->
    ItemCollection.find()
  payments: ->
    PaymentCollection.find()
  usages: ->
    UsageCollection.find()
  events:
    'click [data-remove-button]': (e) ->
      data = e.target.dataset
      if data.scenario
        ScenarioCollection.remove data.scenario
      if data.account
        AccountCollection.remove data.account
      if data.item
        ItemCollection.remove data.item
      if data.payment
        PaymentCollection.remove data.payment
      if data.usage
        UsageCollection.remove data.usage
