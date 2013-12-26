
_.extend Template['account-detail-form'], do ->
  amountInput = null
  nameInput = null
  rendered: ->
    amountInput = @find('[name=amount]')
    nameInput = @find('[name=name]')
  scenario: ->
    currentScenario
  items: ->
    account = Router.getData().account
    payments = currentScenario._payments 
      fromAccount: account._id
      settled: true
    usages = currentScenario._usages
      fromAccount: account._id
    itemsMap = {}
    for payment in payments.fetch()
      payment = new finances.Payment payment
      payment.vivifyAssociates()
      itemNames = 
      finances.buildArithmaticExpression(
        payment.addItems, 
        payment.minusItems
      )
      ((itemsMap[itemNames] ?= {}).payments ?= []).push payment
      payment.itemNames = itemNames
    for usage in usages.fetch()
      item = currentScenario._item usage.item
      ((itemsMap[item.name] ?= {}).usages ?= []).push usage
      usage.item = item
    _.values itemsMap
  showHelp: ->
    Session.get 'showHelp'
  events: do ->
    addOrFetchItem = ->
      name = nameInput.value or 'unspecified'
      item = {
          name: name
          scenario: currentScenario._id
        }
      _.extend(item, 
        ItemCollection.findOne(item) or 
          _id: ItemCollection.insert(item) 
      )
    addPayment = ->
      amount = parseInt amountInput.value or 0
      account = new finances.Account Router.getData().account
      item = addOrFetchItem()
      if amount > 0
        account.pays item, amount
    addUsage = ->
      amount = parseInt amountInput.value or 0
      account = new finances.Account Router.getData().account
      item = addOrFetchItem()
      if amount > 0
        account.uses item, amount
        
    removeAccount = (e) ->
      Meteor.call 'removeAccount', $(e.target).data().account
    removePaymentOrUsage = (e) ->
      Meteor.call 'removePayments', $(e.target).data().payment      
      Meteor.call 'removeUsages',  $(e.target).data().usage

    'click [data-add-payment-button]': addPayment
    'click [data-add-usage-button]': addUsage
    'click [data-remove-button]': removePaymentOrUsage
    'click [data-help]': ->
      Session.set 'showHelp', not Session.get('showHelp')
Template['account-form'].preserve ['input']

