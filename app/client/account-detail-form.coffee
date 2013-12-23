
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
      amount = amountInput.value or 0
      account = new finances.Account Router.getData().account
      item = addOrFetchItem()
      if amount > 0
        account.pays item, amount
    addUsage = ->
      amount = amountInput.value or 0
      account = new finances.Account Router.getData().account
      item = addOrFetchItem()
      if amount > 0
        account.uses item, amount
        
    removeAccount = (e) ->
      Meteor.call 'removeAccount', $(e.target).data().account

    'click [data-add-payment-button]': addPayment
    'click [data-add-usage-button]': addUsage
Template['account-form'].preserve ['input']

