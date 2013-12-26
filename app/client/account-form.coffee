root = this
_.extend Template['account-form'],
  accounts: -> 
    AccountCollection.find()
  message: -> Session.get 'message'
  showHelp: ->
    Session.get 'showHelp'
  created: ->
    Session.set 'message', ''
  events: do ->
    addAccount = (e) ->
      if e.target.value > ''
        _id = AccountCollection.insert scenario: currentScenario._id, name: e.target.value
        e.target.value = ''
        Router.go 'account-detail-form',
          scenario: currentScenario._id
          _id: _id
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
    'click [data-help]': ->
      Session.set 'showHelp', not Session.get('showHelp')
Template['account-form'].preserve ['input']
