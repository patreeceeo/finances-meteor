_.extend Template['item-detail-form'], do ->
  accountIndex = 0
  getItem = ->
    ItemCollection.findOne name: Router.getData().itemName
  getUsers = ->
    AccountCollection.find({}).fetch()
    ItemCollection.find({}).fetch()
    PaymentCollection.find({}).fetch()
    finances.getUsers getItem()
  getPayers = ->
    AccountCollection.find({}).fetch()
    ItemCollection.find({}).fetch()
    PaymentCollection.find({}).fetch()
    p.fromAccount for p in finances.getPaymentsForItem getItem()
  getAccount = ->
    AccountCollection.find({}).fetch()
    accounts = _.values finances.accounts
    accounts[accountIndex]

  created: ->
    accountIndex = 0
  item: itemHelper
  users: usersHelper
  payers: payersHelper
  boths: ->
    _.intersection usersHelper(), payersHelper()
  nothings: ->
    accounts = _.values finances.accounts
    _(accounts).difference usersHelper(), payersHelper()
  account: accountHelper
  events: do ->
    onDragOver = (e) ->
      e.preventDefault?() # allows drop to happen
      e.dataTransfer.dropEffect = 'copy'
      false
    onDragEnter = -> false # just for you, IE
    useAccount = (fn) ->
      (e) ->
        e.stopPropagation?()
        fn.call(this, accountHelper(), itemHelper())
        accounts = _.values finances.accounts
        if accountIndex < accounts.length
          accountIndex++

    'dragstart [data-account]': (e) ->
      e.dataTransfer.effectAllowed = 'copy'
      e.dataTransfer.setData 'text/plain', e.target.dataset.account

    'dragover [data-both-drop-zone]': onDragOver
    'dragenter [data-both-drop-zone]': onDragEnter
    'drop [data-both-drop-zone]': useAccount (account, item) ->
      account.paysAndUses item
    'click [data-both-drop-zone]': useAccount (account, item) ->
      account.paysAndUses item
    'dragover [data-use-drop-zone]': onDragOver
    'dragenter [data-use-drop-zone]': onDragEnter
    'drop [data-use-drop-zone]': useAccount (account, item) ->
      account.uses item
    'click [data-use-drop-zone]': useAccount (account, item) ->
      account.uses item
    'dragover [data-pay-drop-zone]': onDragOver
    'dragenter [data-pay-drop-zone]': onDragEnter
    'drop [data-pay-drop-zone]': useAccount (account, item) ->
      account.pays item
    'click [data-pay-drop-zone]': useAccount (account, item) ->
      item = itemHelper()
      account = accountHelper()
      account.pays item
    'dragover [data-nothing-drop-zone]': onDragOver
    'dragenter [data-nothing-drop-zone]': onDragEnter
    'drop [data-nothing-drop-zone]': useAccount ->
    'click [data-nothing-drop-zone]': useAccount ->
      
_.extend Template['results'], do ->
  externalPayments: ->
    _(finances.payments).where settled: true, toAccount: undefined
  unsettledPayments: ->
    _(finances.payments).where settled: false
  userItem: ->
    result = []
    for item in _.values finances.items
      for user in finances.getUsers(item)
        result.push {account: user, item: item}
      
    result
