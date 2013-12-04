
Template['item-form'].preserve ['input[type=text]', 'input[type=number]']

_.extend Template['item-form'],
  items: -> 
    currentScenario._items()
  message: -> Session.get 'message'
  created: ->
    Session.set 'message', ''
  events: do ->
    item = {}
    addItem = (e) ->
      if item.amount > 0 and item.name isnt ''
        {_id: _id} = currentScenario.addItem item
        Router.go 'item-detail-form',
          scenario: currentScenario._id
          _id: _id
      else
        Session.set 'message', 'Note: enter name and price'
    removeItem = (e) ->
      Meteor.call 'removeItem', $(e.target).data().item
      e.stopImmediatePropagation()
    trackChange = (e) ->
      key = $(e.target).data().input
      value = e.target.value
      item[key] = value
    handlers =
    'click [data-add-button]': addItem
    'change input': trackChange
    'keydown input': (e) ->
      if e.keyCode is 13
        e.preventDefault()
        e.stopPropagation()
        trackChange e
        addItem e
    'click [data-remove-button]': removeItem
    'click [data-item]': (e) ->
      Router.go 'item-detail-form', 
        id: $(e.target).data().item
        scenario: currentScenario._id
