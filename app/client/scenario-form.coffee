
_.extend Template['scenario-form'], do ->
  $name = null
  addScenario = ->
    _id = ScenarioCollection.insert 
      name: $name.val()
      user: Meteor.userId()
    AccountCollection.insert
      name: Meteor.user().username
      scenario: _id
    Router.go 'scenario-detail', _id: _id 
  rendered: ->
    $name = $ 'input[name=scenario-name]'
  message: -> Session.get 'message'
  showHelp: ->
    Session.get 'showHelp'
  scenarios: ->
    ScenarioCollection.find user: Meteor.userId()
  events: 
    'keypress input': (e) ->
      if e.keyCode is 13
        e.preventDefault()
        addScenario()
    'click [data-add-button]': addScenario
    'click [data-remove-button]': (e) ->
      ScenarioCollection.remove $(e.target).data().scenario
    'click [data-help]': ->
      Session.set 'showHelp', not Session.get('showHelp')

