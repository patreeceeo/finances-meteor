
Template['item-form'].preserve ['input[type=text]', 'input[type=number]']

_.extend Template['item-form'],
  items: -> 
    scenarioDep.depend()
    currentScenario._items()
  message: -> Session.get 'message'
  created: ->
    Session.set 'message', ''
  events: do ->
    item = {}
    addItem = (e) ->
      if item.amount > 0 and item.name isnt ''
        currentScenario.addItem item
        Session.set 'message', 'Note: click an item to add people'
        do ->
          parent = $(e.target).parent()
          parent.find('input').val ''
          parent.find('input[type=text]').focus()
        item = {}
      else
        Session.set 'message', 'Note: enter name and price'
    removeItem = (e) ->
      Meteor.call 'removeItem', e.target.dataset.item
      e.stopImmediatePropagation()
    trackChange = (e) ->
      key = e.target.dataset.input
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
        id: e.target.dataset.item
        scenario: currentScenario._id
