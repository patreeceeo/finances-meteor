
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
    @usesItems = []
    @sendsPayments = []
    @receivesPayments = []
  pays: (item, percent = 100) ->
    new Payment item,
      percent: percent
      fromAccount: this
  uses: (item) ->
    finances.getUsers(item).push this
    @usesItems.push item
  paysAndUses: (item, percent = 100) ->
    @pays(item, percent)
    @uses(item)
  owes: ->
    total = 0
    for item in @usesItems
      share = item.amount / finances.getUsers(item).length
      for payment in finances.getPayments(item)
        if payment.fromAccount is this
          share = Math.max 0, share - payment.amount()
      total += share
    total: total

class Payment
  constructor: (@item, @options) ->
    finances.getPayments(@item).push this
    @percent = @options.percent or 100
    @settled = @options.settled or true
    @fromAccount = @options.fromAccount
    @fromAccount?.sendsPayments.push this
    @toAccount = @options.toAccount
    @toAccount?.receivesPayments.push this

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
  simplifyPayments: ->
    # Simplify the payment graph as much as
    # possible without changing the ultimate
    # flow of funds.
    #
    # Pseudocode:
    #
    # For each A1 => A2
    #   If A2 => A3
    #     If A1 => A2 > A2 => A3
    #       (A1 => A3) = (A1 => A2) - (A2 => A3)
    #       (A1 => A2) -= (A1 => A3)
    #       (A2 => A3) = 0
    #     Else If A1 => A2 < A2 => A3
    #       (A1 => A3) = (A2 => A3) - (A1 => A2)
    #       (A2 => A3) -= (A1 => A3)
    #       (A1 => A2) = 0
    #     Else If A1 => A2 is A2 => A3
    #       (A1 => A3) = (A1 => A2)
    #       (A1 => A2) = (A2 => A3) = 0

  Item: Item
  Account: Account
  Payment: Payment

finances.reset()

    

     

