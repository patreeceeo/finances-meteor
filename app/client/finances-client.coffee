
Session.set 'accounts', []
Session.set 'message', 'coffee'

_.extend Template['account-form'],
  accounts: -> Session.get 'accounts'
  message: -> Session.get 'message'
  events: do ->
    addAccount = (e) ->
      accounts = Session.get 'accounts'
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


        
