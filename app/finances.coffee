
#
# dinner:
#   sugardaddy: Fred
#   moochers: Dafny Shaggy Scooby
# hotel:
#   sugermomma: Thelma
#   moochers: Fred Shaggy Scooby

if not _?
  _ = Package?.underscore._

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
    for p in @sendsPayments when not p.settled
      share = p.item.amount / finances.getUsers(p.item).length
      # for payment in finances.getPayments(item)
      #   if payment.fromAccount is this
      #     share = Math.max 0, share - payment.amount()
      console.debug "add payment from #{p.fromAccount.name} to #{p.toAccount?.name} for #{p.item.name}"
      total += share
    total: total

class Payment
  constructor: (@item, @options) ->
    finances.getPayments(@item).push this
    @percent = @options.percent or 100
    @settled = if @options.settled? then @options.settled else true
    @fromAccount = @options.fromAccount
    @fromAccount?.sendsPayments.push this
    @toAccount = @options.toAccount
    @toAccount?.receivesPayments.push this
    console.debug "create#{if @settled then ' ' else ' unsettled '}payment from #{@fromAccount.name} to #{@toAccount?.name} for #{@item.name}"

  amount: ->
    @item.amount * (@percent/100)
  isInternal: ->
    @fromAccount? and @toAccount? 

@finances ?=
  getPayments: (item) ->
    @payments[item.name] ?= []
  getUsers: (item) ->
    @users[item.name] ?= []
  reset: ->
    @items = {}
    @payments = {}
    @users = {}
  deletePayment: (p) ->
    console.debug "delete payment from #{p.fromAccount.name} to #{p.toAccount?.name} for #{p.item.name}"
    deleteFromArray = (parent, prop, value) ->
      parent[prop] = _(parent[prop]).without(value)
    deleteFromArray p.fromAccount, 'sendsPayments', p
    deleteFromArray p.toAccount, 'receivesPayments', p
    delete @payments[p.item.name]
    console.debug "#{p.fromAccount.name} sends payments",p.fromAccount.sendsPayments
    p.settled = true
  createInternalPayments: ->
    for item in _.values(@items)
      for p in @getPayments(item) when p.settled
        for user in @getUsers(item)
          new Payment item,
            toAccount: p.fromAccount
            fromAccount: user
            percent: 100 / @getUsers(item).length
            settled: false
    undefined
  simplifyPayments: ->
    # Simplify the payment graph as much as
    # possible without changing the ultimate
    # flow of $$$.
    #
    # Pseudo-code for a general solution:
    # The => symbol represents a payment between two accounts
    # Arithmetic operations with payments are performed with payment amounts
    # Assignment operations create payments if none existed previously
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

    # Implemenation: currently assumes all payments are 100%, so not a general
    #                solution.
    for item in _.values(@items)
      for p in @getPayments(item) when not p.settled and p.isInternal()
        # A possible optimization:
        #   if p.toAccount is p2.fromAccount
        #     @deletePayment(p)
        #   else
        for p2 in @getPayments(item) when not p2.settled and p2.isInternal() and p2.toAccount is p2.fromAccount
          p.toAccount = p2.toAccount
          @deletePayment(p2)
    undefined
          
  Item: Item
  Account: Account
  Payment: Payment

finances.reset()

    

     

