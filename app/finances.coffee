
#
# dinner:
#   sugardaddy: Fred
#   moochers: Dafny Shaggy Scooby
# hotel:
#   sugermomma: Thelma
#   moochers: Fred Shaggy Scooby

class Item
  constructor: (@name, @amount) ->
    finances.items[@name] = this

class Account
  constructor: (@name) ->
  pays: (item, percent = 100) ->
    new Payment(this, item, percent)
  uses: (item) ->
    finances.getUsers(item).push this

class Payment
  constructor: (@account, @item, @percent) ->
    finances.getPayments(item).push this

@finances ?=
  getPayments: (item) ->
    @payments[item.name] ?= []
  getUsers: (item) ->
    @users[item.name] ?= []
  reset: ->
    @items = {}
    @payments = {}
    @users = {}
  Item: Item
  Account: Account
  Payment: Payment

finances.reset()

    

     

