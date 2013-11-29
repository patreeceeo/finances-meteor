root = this
_.extend Template['account-form'],
  accounts: -> 
    currentScenario._accounts()
  message: -> Session.get 'message'
  created: ->
    Session.set 'message', ''
  events: do ->
    addAccount = (e) ->
      if e.target.value > ''
        currentScenario.addAccount name: e.target.value
        e.target.value = ''
    removeAccount = (e) ->
      Meteor.call 'removeAccount', $(e.target).data().account

    'change input': addAccount
    'focusout input': addAccount
    'keydown input': (e) ->
      if e.keyCode is 13
        e.preventDefault()
        e.stopPropagation()
        addAccount e
    'click [data-remove-button]': removeAccount
Template['account-form'].preserve ['input']
