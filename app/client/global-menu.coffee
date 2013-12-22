
_.extend Template['global-menu'], do ->
  creator = ->
    currentScenario?.deps.user.depend()
    currentScenario?.user
  rendered: ->
    if currentScenario?
      $('head title').text "“#{currentScenario.name}” by #{creator().username} - Divvy"
  message: -> Session.get 'message'
  scenario: ->
    if currentScenario?
      currentScenario
  user: ->
    Meteor.user()
  creator: creator
  events:
    'click [data-next-button]': ->
      if not nextButtonDisabled()
        Router.go nextPage(), scenario: currentScenario._id
    'click [data-up-button]': ->
      if not upButtonDisabled()
        Router.go upPage(), scenario: currentScenario._id
    'click [data-reset-button]': ->
      Meteor.call 'reset', 
        scenario: currentScenario._id, 
        (error, result) ->
          Router.go 'account-form', scenario: currentScenario._id
    'click [data-flash-message]': ->
      Session.set 'message', ''
    'click [data-logout-button]': ->
      Meteor.logout (error) ->
        unless error?
          Router.go 'home'
        else
          Session.set 'message', error.message

