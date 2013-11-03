
Session.set 'accounts', []
Session.set 'items', []
Session.set 'message', 'coffee'

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

_.extend Template['item-form'],
  items: -> Session.get 'items'
  message: -> Session.get 'message'
  events: do ->
    item = {}
    setField = (e) ->
      key = e.target.dataset.input
      value = e.target.value
      item[key] = value
      if item.amount > 0 and item.name isnt ''
        items = Session.get 'items'
        items.unshift new finances.Item item.name, item.amount
        Session.set 'items', items
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

    handlers =
    'focusout input': setField
    'keydown input': (e) ->
      if e.keyCode is 13
        e.preventDefault()
        e.stopPropagation()
        setField e
    'click [data-remove-button]': removeItem

Template['account-form'].preserve ['input']
Template['item-form'].preserve ['input[type=text]', 'input[type=number]']


        
