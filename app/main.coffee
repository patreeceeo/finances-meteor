
if Meteor.isClient

  Handlebars.registerHelper 'round', (options) ->
    number = parseFloat options.fn(this)
    string = "#{finances.round number}"
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
  if @ready()
    if not Meteor.user()?
      @render 'login'
      @stop()

root = this
loadAllScenarios = ->
  @subscribe('scenarios', {}).wait()

loadCurrentScenario = ->
  scenarioId = @params.scenario or @params._id
  @subscribe('scenarios', scenarioId).wait()
  @subscribe('accounts', scenario: scenarioId).wait()
  @subscribe('items', scenario: scenarioId).wait()
  @subscribe('payments', scenario: scenarioId).wait()
  @subscribe('usages', scenario: scenarioId).wait()

  if @ready() 
    scenario = ScenarioCollection.findOne()
    if scenario?
      root.currentScenario = new finances.Scenario
      root.currentScenario._id = scenarioId
      _.extend root.currentScenario, scenario

      root.currentScenario.deps =
        user: new Deps.Dependency
      Meteor.call 'findUsers', _id: currentScenario?.user, (error, users) ->
        currentScenario.user = users[0]
        root.currentScenario.deps.user.changed()
    else
      @render 'not-found'
      @stop()

Router.configure
  loadingTemplate: 'loading'
  notFoundTemplate: 'not-found'

Router.before loadCurrentScenario, except: ['home', 'login', 'create-account', 'admin-login', 'admin', 'scenario-form', 'find-scenario']
Router.before redirectAnonymous, except: ['home', 'login', 'create-account', 'admin-login', 'admin']

Router.map ->

  @route 'home',
    path: '/'

  @route 'login'
  @route 'create-account'

  @route 'scenario-form',
    path: '/scenarios'
    before: loadAllScenarios

  @route 'find-scenario',
    path: '/find-scenario'
    before: loadAllScenarios

  @route 'account-form',
    path: 'scenarios/:scenario/accounts'
    data: ->
      scenarioId: @params.scenario

  @route 'scenario-detail',
    path: 'scenarios/:_id'
    data: ->
      scenarioId: @params._id


  @route 'item-form',
    path: 'scenarios/:scenario/items'
    data: ->
      scenarioId: @params.scenario

  @route 'account-detail-form',
    path: 'scenarios/:scenario/accounts/:_id'
    data: ->
      account = AccountCollection.findOne(@params._id)
      if account?
        scenarioId: @params.scenario
        account: account

  @route 'report',
    path: 'scenarios/:_id/report'

  @route 'report-payment-detail',
    path: 'scenarios/:scenario/report/:_id'
    data: ->
      payment = PaymentCollection.findOne(@params._id)
      if payment?
        scenarioId: @params.scenario
        payment: payment

  @route 'admin-login'

  @route 'admin',
    before: ->
      Deps.autorun =>
        adminUser = Session.get('adminUser') 
        Meteor.call 'getAdminCreds', (error, result) =>
          if adminUser isnt result.pretzel
            @redirect 'admin-login'




