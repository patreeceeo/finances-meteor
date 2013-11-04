
Session.set 'accounts', []
Session.set 'items', []
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


_.extend Template['item-detail-form'],
  itemName: ->
    Router.getData().itemName
  events: do ->
    'dragstart [data-account]': (e) ->
      e.dataTransfer.dropEffect = e.dataTransfer.effectAllowed = 'move'

    'drop [data-both-drop-zone]': (e) ->
      # account = finances.accounts[e.target.dataset.account]
      # item = finances.items[
      # account.paysAndUses
      
