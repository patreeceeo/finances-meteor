
_.extend Template['login'], do ->
  $password = $username = null
  login = ->
    Meteor.loginWithPassword $username.val(), $password.val(),
      (error) ->
        if error
          switch error.error
            when 403
              Session.set 'message', "Sorry, that combination isn't recognized."
            else
              Session.set 'message', error.message
        else
          Session.set 'loggedIn', true
          Router.go 'scenario-form'
  rendered: ->
    $password = $ 'input[name=password]'
    $username = $ 'input[name=username]'
  message: -> Session.get 'message'
  events: 
    'keypress input': (e) ->
      if e.keyCode is 13
        e.preventDefault()
        login()
    'click [data-create-account-button]': ->
      Router.go 'create-account'
    'click [data-login-button]': login
    'click [data-flash-message]': ->
      Session.set 'message', ''

