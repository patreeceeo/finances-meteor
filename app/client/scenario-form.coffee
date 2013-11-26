
_.extend Template['scenario-form'], do ->
  $name = null
  addScenario = ->
    _id = ScenarioCollection.insert 
      name: $name.val()
      user: Meteor.userId()
    Router.go 'account-form', scenario: _id 
  rendered: ->
    $name = $ 'input[name=scenario-name]'
  message: -> Session.get 'message'
  scenarios: ->
    ScenarioCollection.find user: Meteor.userId()
  events: 
    'keypress input': (e) ->
      if e.keyCode is 13
        e.preventDefault()
        addScenario()
    'click [data-add-button]': addScenario
    'click [data-link]': (e) ->
      Router.go 'account-form', scenario: e.target.dataset.scenario
    'click [data-remove-button]': (e) ->
      ScenarioCollection.remove e.target.dataset.scenario

