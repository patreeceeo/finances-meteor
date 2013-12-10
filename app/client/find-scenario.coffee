
_.extend Template['find-scenario'], do ->
  scenarios = null
  dep = new Deps.Dependency()
  search = (username) ->
    Meteor.call 'findUsers', username: username, (error, users) ->
      if users[0]
        scenarios = ScenarioCollection.find(user: users[0]._id).fetch()
      else
        scenarios = null
        Session.set 'message', "That user doesn't exist"
      dep.changed()
  scenarios: -> 
    dep.depend()
    scenarios ?= []
  created: ->
    scenarios = null
  events:
    'click [data-link][data-scenario]': (e) ->
      Router.go 'account-form', scenario: $(e.target).data().scenario
    'click [data-search-button]': ->
      search $('[name=user-name]').val()
    'keydown input': (e) ->
      if e.keyCode is 13
        e.preventDefault()
        search e.target.value
   
