
_.extend Template['account-form'],
  accounts: -> AccountCollection.find()
  message: -> Session.get 'message'
  created: ->
    Session.set 'message', ''
  events: do ->
    addAccount = (e) ->
      if e.target.value > ''
        AccountCollection.insert name: e.target.value
        e.target.value = ''
    removeAccount = (e) ->
      AccountCollection.remove name: e.target.dataset.account

    'change input': addAccount
    'focusout input': addAccount
    'keydown input': (e) ->
      if e.keyCode is 13
        e.preventDefault()
        e.stopPropagation()
        addAccount e
    'click [data-remove-button]': removeAccount
Template['account-form'].preserve ['input']
