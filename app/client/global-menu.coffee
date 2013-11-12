
_.extend Template['global-menu'], do ->
  page = -> Router.getData().page
  nextPage = -> Router.getData().nextPage
  upPage = -> Router.getData().upPage
  stepNumber = -> Router.getData().stepNumber

  nextButtonDisabled = ->
    not nextPage()? or
    switch page()
      when 'item-form'
        ItemCollection.find({}).count() < 2
      when 'account-form'
        AccountCollection.find({}).count() < 2
  upButtonDisabled = -> not upPage()?
  nextButtonDisabled: nextButtonDisabled
  upButtonDisabled: upButtonDisabled
  stepNumber: -> stepNumber()
  events:
    'click [data-next-button]': ->
      if not nextButtonDisabled()
        Router.go nextPage()
    'click [data-up-button]': ->
      if not upButtonDisabled()
        Router.go upPage()

