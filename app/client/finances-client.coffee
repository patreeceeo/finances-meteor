
Session.set 'accounts', [
  new finances.Account 'dude'
  new finances.Account 'walter'
  ]
Session.set 'items', [
  new finances.Item 'ball', 6
  new finances.Item 'whiterussian', 6
]
Session.set 'message', ''

_.extend Template['global-menu'], do ->

  nextButtonDisabled = ->
    not Router.getData().nextPage? or
    switch Router.getData().page
      when 'item-form'
        items = Session.get('items')
        items.length < 2
      when 'account-form'
        accounts = Session.get('accounts')
        accounts.length < 2
  upButtonDisabled = ->
    not Router.getData().upPage?
  nextButtonDisabled: nextButtonDisabled
  upButtonDisabled: upButtonDisabled
  stepNumber: ->
    Router.getData().stepNumber
  events: do ->
    'click [data-next-button]': ->
      if not nextButtonDisabled()
        Router.go Router.getData().nextPage
    'click [data-up-button]': ->
      if not upButtonDisabled()
        Router.go Router.getData().upPage

_.extend Template['account-form'],
  accounts: -> Session.get 'accounts'
  message: -> Session.get 'message'
  events: do ->
    addAccount = (e) ->
      accounts = Session.get 'accounts'
      if e.target.value > ''
        accounts.unshift new finances.Account e.target.value
        Session.set 'accounts', accounts
        e.target.value = ''
    removeAccount = (e) ->
      accounts = Session.get 'accounts'
      deleted = _(accounts).findWhere name: e.target.dataset.account
      accounts = _(accounts).without deleted
      Session.set 'accounts', accounts

    handlers =
    'change input': addAccount
    'focusout input': addAccount
    'keydown input': (e) ->
      if e.keyCode is 13
        e.preventDefault()
        e.stopPropagation()
        addAccount e
    'click [data-remove-button]': removeAccount
Template['account-form'].preserve ['input']

_.extend Template['item-form'],
  items: -> Session.get 'items'
  message: -> Session.get 'message'
  events: do ->
    item = {}
    addItem = (e) ->
      if item.amount > 0 and item.name isnt ''
        items = Session.get 'items'
        items.unshift new finances.Item item.name, item.amount
        Session.set 'items', items
        Session.set 'message', 'Note: click an item to add people'
        do ->
          parent = $(e.target).parent()
          parent.find('input').val ''
          parent.find('input[type=text]').focus()
        item = {}
    removeItem = (e) ->
      items = Session.get 'items'
      deleted = _(items).findWhere name: e.target.dataset.item
      items = _(items).without deleted
      Session.set 'items', items
    trackChange = (e) ->
      key = e.target.dataset.input
      value = e.target.value
      item[key] = value
    handlers =
    'click [data-add-button]': addItem
    'change input': trackChange
    'keydown input': (e) ->
      if e.keyCode is 13
        e.preventDefault()
        e.stopPropagation()
        trackChange e
        addItem e
    'click [data-remove-button]': removeItem
    'click [data-item]': (e) ->
      Router.go 'item-detail-form', name: e.target.dataset.item

Template['item-form'].preserve ['input[type=text]', 'input[type=number]']


_.extend Template['item-detail-form'], do ->
  usersDep = new Deps.Dependency
  payersDep = new Deps.Dependency
  accountDep = new Deps.Dependency
  accountIndex = 0
  itemHelper = ->
    finances.items[Router.getData().itemName]
  usersHelper = ->
    usersDep.depend()
    finances.getUsers(itemHelper())
  payersHelper = ->
    payersDep.depend()
    p.fromAccount for p in finances.getPaymentsForItem itemHelper()
  accountHelper = ->
    accountDep.depend()
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
        usersDep.changed()
        payersDep.changed()
        accounts = _.values finances.accounts
        if accountIndex < accounts.length
          accountIndex++
          accountDep.changed()

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
