
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
    @itemsUsed = []
  pays: (item, percent = 100) ->
    new Payment(this, item, percent)
  uses: (item) ->
    finances.getUsers(item).push this
    @itemsUsed.push item
  paysAndUses: (item, percent = 100) ->
    @pays(item, percent)
    @uses(item)
  owes: ->
    total = 0
    for item in @itemsUsed
      share = item.amount / finances.getUsers(item).length
      for payment in finances.getPayments(item)
        if payment.account is this
          share = Math.max 0, share - payment.amount()
      total += share 
    total: total

class Payment
  constructor: (@account, @item, @percent) ->
    finances.getPayments(item).push this
  amount: ->
    @item.amount * (@percent/100)

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

    

     

