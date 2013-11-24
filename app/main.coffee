
if Meteor.isClient
  _.extend Session, do ->
    _set = Session.set
    _get = Session.get
    set: (key, value) ->
      _set.apply this, arguments
      amplify.store key, value
    setDefault: (key, value) ->
      unless amplify.store(key)?
        _set.apply this, arguments
        amplify.store key, value
    get: (key) ->
      _get.apply this, arguments
      amplify.store key
  Meteor.startup ->
    Session.setDefault 'adminUser', false

Router.map ->
  @route 'home',
    path: '/'
  @route 'account-form',
    path: ':scenario/accounts'
    data: ->
      scenarioId: @params.scenario
      page: 'account-form'
      nextPage: 'item-form'

  @route 'item-form',
    path: ':scenario/items'
    data: ->
      scenarioId: @params.scenario
      page: 'item-form'
      nextPage: 'results'

  @route 'item-detail-form',
    path: ':scenario/item/:id'
    data: ->
      scenarioId: @params.scenario
      itemId: @params.id
      page: 'item-detail-form'
      upPage: 'item-form'
      nextPage: 'results'

  @route 'results',
    path: ':scenario/results'

  @route 'admin-login'

  @route 'admin',
    before: ->
      Deps.autorun =>
        if not Session.get 'adminUser'
          @redirect 'admin-login'



