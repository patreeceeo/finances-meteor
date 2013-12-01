
_.extend Template['global-menu'], do ->
  page = -> Router.getData().page
  nextPage = -> Router.getData().nextPage
  upPage = -> Router.getData().upPage

  nextButtonDisabled = ->
    not nextPage()? or
    switch page()
      when 'item-form'
        currentScenario?._items().count() < 1
      when 'item-detail-form'
        currentScenario?._items().count() < 1
      when 'account-form'
        currentScenario?._accounts().count() < 2
      else 
        false
  upButtonDisabled = -> not upPage()?
  creator = ->
    Meteor.users.findOne(currentScenario?.user)
  rendered: ->
    if currentScenario?
      $('head title').text "“#{currentScenario.name}” by #{creator().username} - Divvy"
  nextButtonDisabled: nextButtonDisabled
  upButtonDisabled: upButtonDisabled
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

