
Template['item-form'].preserve ['input[type=text]', 'input[type=number]']

_.extend Template['item-form'],
  items: -> ItemCollection.find({}).count()
  message: -> Session.get 'message'
  events: do ->
    item = {}
    addItem = (e) ->
      if item.amount > 0 and item.name isnt ''
        AccountCollection.insert item
        Session.set 'message', 'Note: click an item to add people'
        do ->
          parent = $(e.target).parent()
          parent.find('input').val ''
          parent.find('input[type=text]').focus()
        item = {}
    removeItem = (e) ->
      ItemCollection.remove name: e.target.dataset.item
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
      Router.go 'item-detail-form', name: e.target.dataset.item
