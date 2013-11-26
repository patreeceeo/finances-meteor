
_.extend Template['create-account'], do ->
  $password1 = $password2 = $username = null
  createAccount = ->
    if $password1.val() is $password2.val()
      Accounts.createUser 
        username: $username.val()
        password: $password1.val()
        (error) ->
          if error
            Session.set 'message', error.message
          else
            Session.set 'loggedIn', true
            Router.go 'scenario-form'
    else
      Session.set 'message', 'Make sure the password fields match'
  rendered: ->
    $password1 = $ 'input[name=password1]'
    $password2 = $ 'input[name=password2]'
    $username = $ 'input[name=username]'
  message: -> Session.get 'message'
  events: 
    'keypress input': (e) ->
      if e.keyCode is 13
        e.preventDefault()
        createAccount()
    'click [data-create-account-button]': createAccount
    'click [data-login-button]': ->
      Router.go 'login'
    'click [data-flash-message]': ->
      Session.set 'message', ''

