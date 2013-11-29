
if Meteor.isClient

  Handlebars.registerHelper 'round', (options) ->
    number = parseFloat options.fn(this)
    string = "#{Math.round(number * 100) / 100}"
    pointPosition = _(string).indexOf('.')
    if pointPosition isnt -1
      if string.length - pointPosition is 2
        string += '0'
    string

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
    Session.setDefault 'user', false

redirectAnonymous = ->
  if not Meteor.user()?
    @render 'login'
    @stop()

root = this
loadCurrentScenario = ->
  scenarioId = @params.scenario
  scenario = ScenarioCollection.findOne scenarioId
  if scenario?
    root.currentScenario = new finances.Scenario
    root.currentScenario._id = scenarioId
    _.extend root.currentScenario, scenario
  else
    Router.go 'scenario-form'

Router.configure
  loadingTemplate: 'loading'

Router.before loadCurrentScenario, except: ['home', 'login', 'create-account', 'admin-login', 'admin', 'scenario-form', 'find-scenario']
Router.before redirectAnonymous, except: ['home', 'login', 'create-account', 'admin-login', 'admin']

Router.map ->

  @route 'home',
    path: '/'

  @route 'login'
  @route 'create-account'

  @route 'scenario-form',
    path: '/scenarios'

  @route 'find-scenario',
    path: '/find-scenario'

  @route 'account-form',
    path: '/:scenario/accounts'
    data: ->
      scenarioId: @params.scenario
      page: 'account-form'
      nextPage: 'item-form'


  @route 'item-form',
    path: '/:scenario/items'
    data: ->
      scenarioId: @params.scenario
      page: 'item-form'
      nextPage: 'report'

  @route 'item-detail-form',
    path: '/:scenario/item/:_id'
    data: ->
      scenarioId: @params.scenario
      itemId: @params._id
      page: 'item-detail-form'
      upPage: 'item-form'
      nextPage: 'report'

  @route 'report',
    path: '/:scenario/report'

  @route 'report-payment-detail',
    path: '/:scenario/report/:_id'
    data: ->
      scenarioId: @params.scenario
      paymentId: @params._id

  @route 'admin-login'

  @route 'admin',
    before: ->
      Deps.autorun =>
        adminUser = Session.get('adminUser') 
        Meteor.call 'getAdminCreds', (error, result) =>
          if adminUser isnt result.pretzel
            @redirect 'admin-login'



