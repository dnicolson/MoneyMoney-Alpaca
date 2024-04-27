WebBanking{version     = 0.2,
           url         = "https://alpaca.markets/",
           services    = {"Alpaca"},
           description = "Cash balance and securities portfolio from Alpaca"}

local connection = Connection()
local apiKey
local apiSecret

function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Alpaca"
end

function InitializeSession (protocol, bankCode, username, reserved, password)
  apiKey = username
  apiSecret = password
end

function ListAccounts (knownAccounts)
  local response = apiRequest("account")
  local accounts = {}

  table.insert(accounts, {
    accountNumber = response["account_number"],
    currency = response["currency"],
    name = "Alpaca Cash",
    type = AccountTypeGiro
  })

  table.insert(accounts, {
    accountNumber = "Securities",
    currency = response["currency"],
    name = "Alpaca Securities",
    portfolio = true,
    type = AccountTypePortfolio
  })

  return accounts
end

function RefreshAccount (account, since)
  if account.type == AccountTypeGiro then
    local response = apiRequest("account")
    local cash = response["cash"]

    if cash ~= account.balance then
      local transaction = {
        bookingDate = os.time(),
        purpose = "Cash",
        amount = cash
      }

      return { balance=cash, transactions={transaction} }
    end
  elseif account.type == AccountTypePortfolio then
    local response = apiRequest("positions")
    local s = {}

    for _, position in ipairs(response) do
      s[#s+1] = {
        amount = position.market_value,
        bookingDate = since,
        market = position.exchange,
        name = position.symbol,
        price = position.current_price,
        purchasePrice = position.cost_basis / position.qty,
        quantity = position.qty,
        securityNumber = position.symbol
      }
    end

    return { securities = s }
  end
end

function EndSession ()
end

function apiRequest(endpoint)
  local apiUrl = "https://api.alpaca.markets/v2/" .. endpoint

  local headers = {
    ["APCA-API-KEY-ID"] = apiKey,
    ["APCA-API-SECRET-KEY"] = apiSecret
  }

  response = connection:request("GET", apiUrl, nil, nil, headers)

  return JSON(response):dictionary()
end
