
log =
  write: ->
    # console.debug.apply console, arguments

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
  constructor: (@attributes) ->
    @name = @attributes.name
    @amount = @attributes.amount
    @scenario = @attributes.scenario
    @scenario.items.push this
  clone: (name = @name) ->
    attributes = _.clone(@attributes)
    attributes.name = name
    new Item(attributes)

class Account
  constructor: (@attributes) ->
    @name = @attributes.name
    @usesItems = @attributes.usesItems or []
    @sendsPayments = @attributes.sendsPayments or []
    @receivesPayments = @attributes.receivesPayments or []
    @scenario = @attributes.scenario
    @scenario.accounts.push this
  pays: (item, percent = 100) ->
    new Payment
      item: item
      percent: percent
      fromAccount: this
      scenario: @scenario
  uses: (item) ->
    @usesItems.push item
  paysAndUses: (item, percent = 100) ->
    @pays(item, percent)
    @uses(item)
  owes: ->
    total = 0
    for p in @sendsPayments when not p.settled
      log.write "include in total #{p.toString()}"
      total += p.amount
    total: total

class Payment
  constructor: (@attributes) ->
    @item = @attributes.item
    @percent = @attributes.percent or 100
    @scenario = @attributes.scenario
    if @item?
      @scenario.getPaymentsForItem(@item).push this

    @scenario.payments.push this
    @amount =
    if @item?
      @item.amount *
      if @percent
        100 / @percent
      else
        1 / @scenario.getUsers(@item).length
    else
      @attributes.amount or 0
      
    @settled = if @attributes.settled? then @attributes.settled else true
    @fromAccount = @attributes.fromAccount
    @fromAccount?.sendsPayments.push this
    @toAccount = @attributes.toAccount
    @toAccount?.receivesPayments.push this
    log.write "create #{@toString()}"

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


class Scenario
  constructor: (@attributes) ->
    @accounts = []
    @items = []
    @payments = []
  createAccount: (doc) ->
    new Account _.extend doc, scenario: this
  createItem: (doc) ->
    new Item _.extend doc, scenario: this
  createPayment: (doc) ->
    new Payment _.extend doc, scenario: this
  getPaymentsForItem: (item) ->
    _(@payments).filter (p) ->
      p.item is item
  getUsers: (item) ->
    _(@accounts).filter (a) ->
      _(a.usesItems).contains item
      
  deletePayment: (deleteMe) ->
    log.write "delete #{deleteMe.toString()}"
    deleteFrom = (propName) ->
      in: (object) ->
        object[propName] =
        _(object[propName]).reject (o) ->
          o is deleteMe

    deleteFrom('sendsPayments').in(deleteMe.fromAccount)
    deleteFrom('receivesPayments').in(deleteMe.toAccount)

    # TODO: should a payment actually be made settled after
    #       it's deleted?
    deleteMe.settled = true
  createOrIncreasePayment: (attributes) ->
    payments = _(@payments).filter (p) ->
      p.fromAccount is attributes.fromAccount and
        p.toAccount is attributes.toAccount
    if payments[0]
      log.write "increase #{payments[0].toString()} by $#{attributes.amount}"
      payments[0].amount += attributes.amount
      payments[0]
    else
      @createPayment attributes
  createInternalPayments: ->
    for item in @items
      for p in @getPaymentsForItem(item) when p.settled
        for user in @getUsers(item) when user isnt p.fromAccount
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

    # Implemenation:

    payments = _(@payments)
      .sortBy('amount')
      .filter (p) -> not p.settled and p.isInternal()

    for p in payments
      for p2 in payments when p.toAccount is p2.fromAccount and
          not (p.settled or p2.settled)
        log.write """#{
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
          if p.fromAccount isnt p2.toAccount
            log.write "redirect #{p.toString()} to #{p2.toAccount.name}"
            p.toAccount = p2.toAccount
          else
            @deletePayment(p)
          @deletePayment(p2)
        else
          minflow = Math.min(p.amount, p2.amount)

          if p.fromAccount isnt p2.toAccount
            payments.push newp = @createOrIncreasePayment
              fromAccount: p.fromAccount
              toAccount: p2.toAccount
              amount: minflow
              settled: false
              
          if p.amount > p2.amount
            log.write "decrease #{p.toString()} by $#{minflow}"
            if p.amount > minflow
              p.amount -= minflow
            else
              @deletePayment(p)
            @deletePayment(p2)
          else
            log.write "decrease #{p2.toString()} by $#{minflow}"
            if p2.amount > minflow
              p2.amount -= minflow
            else
              @deletePayment(p2)
            @deletePayment(p)

    undefined

  getPRNG: (seed) ->
    (min, max) ->
      x = Math.sin(seed++) * 10000
      r = x - Math.floor(x)
      Math.round r * (max - min) + min
  testScenario: (seed) ->

    random = @getPRNG(seed)
    totalPayments = 0

    nUsers = random(2, 10)
    nPayers = random(2, 10)

    nAccounts = do ->
      min = Math.max(nUsers, nPayers)
      random(min, nUsers + nPayers)
    nItems = random(nAccounts / 2, nAccounts * 2)

    accounts = (new Account "account #{i}" for i in [1..nAccounts])
    items =
      for i in [1..nItems]
        new Item name: "item #{i}", amount: random(2, 30)

    for index, item of items
      accounts[index % nPayers].pays item
      accounts[accounts.length - 1 - index % nUsers].uses item
      totalPayments += item.amount

    totalPayments: totalPayments
    accounts: accounts
    items: items


@finances =
  Item: Item
  Account: Account
  Payment: Payment
  Scenario: Scenario


    

     

