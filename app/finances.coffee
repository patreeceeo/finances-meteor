
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
    new Payment
      item: item
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
      # share =
      # if p.item?
      #   p.amount / finances.getUsers(p.item).length
      # else
      #   p.amount
      
      console.debug "add #{p.toString()} to total"
      total += p.amount
    total: total

class Payment
  constructor: (@options) ->
    finances.payments.push this
    @item = @options.item
    @percent = @options.percent or 100
    if @item?
      finances.getPaymentsForItem(@item).push this

    @amount =
    if @item?
      @item.amount *
      if @percent
        100/@percent
      else
        1/@getUsers(@item).length
    else
      @options.amount or 0
      
    @settled = if @options.settled? then @options.settled else true
    @fromAccount = @options.fromAccount
    @fromAccount?.sendsPayments.push this
    @toAccount = @options.toAccount
    @toAccount?.receivesPayments.push this
    console.debug "create #{@toString()}"

  # amount: ->
  #   @amount * (@percent/100)
  isInternal: ->
    @fromAccount? and @toAccount?
  toString: ->
    """#{
    if @settled
      ''
    else
      'unsettled '
    }payment from #{
      @fromAccount.name
    } to #{
      @toAccount?.name
    } for #{
      @item?.name
    } ($#{
      @amount
    })"""

@finances ?=
  getPaymentsForItem: (item) ->
    @paymentsForItem[item.name] ?= []
  getUsers: (item) ->
    @users[item.name] ?= []
  reset: ->
    @items = {}
    @paymentsForItem = {}
    @users = {}
    @payments = []
  deletePayment: (p) ->
    console.debug "delete #{p.toString()}"
    deleteFromArray = (parent, prop, value) ->
      parent[prop] = _(parent[prop]).without(value)
    deleteFromArray p.fromAccount, 'sendsPayments', p
    deleteFromArray p.toAccount, 'receivesPayments', p
    if p.item?
      delete @paymentsForItem[p.item.name]
    p.settled = true
  createOrIncreasePayment: (options) ->
    payments = _(@payments).filter (p) ->
      p.fromAccount is options.fromAccount and p.toAccount is options.toAccount
    if payments[0]
      payments[0].amount += options.amount
      payments[0]
    else
      new Payment options
  createInternalPayments: ->
    for item in _.values(@items)
      for p in @getPaymentsForItem(item) when p.settled
        for user in @getUsers(item)
          @createOrIncreasePayment
            amount: item.amount / @getUsers(item).length
            toAccount: p.fromAccount
            fromAccount: user
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
    #       (A1 => A3) += (A1 => A2) - (A2 => A3)
    #       (A1 => A2) -= (A1 => A3)
    #       (A2 => A3) = 0
    #     Else If A1 => A2 < A2 => A3
    #       (A1 => A3) += (A2 => A3) - (A1 => A2)
    #       (A2 => A3) -= (A1 => A3)
    #       (A1 => A2) = 0
    #     Else If A1 => A2 is A2 => A3
    #       (A1 => A3) = (A1 => A2)
    #       (A1 => A2) = (A2 => A3) = 0

    # Implemenation: currently assumes all payments are
    #                100%, so not a general
    #                solution.
    payments = _(@payments)
      .sortBy('amount')
      .filter (p) -> not p.settled and p.isInternal()

    console.debug 'payments', payments
    for p in payments
      for p2 in payments when p.toAccount is p2.fromAccount and
          not (p.settled or p2.settled)
        console.debug """#{
          p.fromAccount.name
        } owes $#{
          p.amount
        } to #{
          p.toAccount.name
        } and #{
          p2.fromAccount.name
        } owes $#{
          p2.amount
        } to #{
          p2.toAccount.name
        }"""

        if p.amount is p2.amount
          p.toAccount = p2.toAccount
          @deletePayment(p2)
        else
          newp = @createOrIncreasePayment
            fromAccount: p.fromAccount
            toAccount: p2.toAccount
            amount: Math.min(p.amount, p2.amount)
          if p.amount > p2.amount
            console.debug "decrease #{p.toString()} by #{newp.amount}"
            p.amount -= newp.amount
            @deletePayment(p2)
          else
            console.debug "decrease #{p.toString()} by #{newp.amount}"
            p2.amount -= newp.amount
            @deletePayment(p)

    undefined
          
  Item: Item
  Account: Account
  Payment: Payment

finances.reset()

    

     

