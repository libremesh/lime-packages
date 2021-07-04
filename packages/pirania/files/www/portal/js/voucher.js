var validMacs = []
var userIp = null
var userMac = null
var userIsValid = null

var voucherButton = document.getElementById('voucherInput-submit')
let voucherElem = document.getElementById('voucher')

const validMacsForm = {
  id: 99,
  jsonrpc: '2.0',
  method: 'call',
  params: [
    '00000000000000000000000000000000',
    'pirania',
    'print_valid_macs',
    {}
  ]
}

const validGetClients = {
  id: 99,
  jsonrpc: '2.0',
  method: 'call',
  params: [
    '00000000000000000000000000000000',
    'pirania-app',
    'get_clients',
    {}
  ]
}

async function loadAsyncData () {
  await getIp()
  await getValidClients()
  await getValidMacs()
}

function init () {
  console.log('Welcome to Pirania!')
  // Add responses
  var error = document.createElement('h4')
  var result = document.createElement('p')
  var form = document.getElementsByClassName('voucher')[0]
  form.append(error)
  form.append(result)
  error.setAttribute('id', 'error')
  result.setAttribute('id', 'result')
  error.className = 'hidden'
  result.className = 'hidden'

  // Add list
  var deviceList = document.createElement('button')
  var add = document.createElement('span')
  var icon = document.createElement('div')
  document.body.appendChild(deviceList)
  deviceList.appendChild(add)
  deviceList.appendChild(icon)
  icon.className = 'mobile icon'
  add.innerHTML = '+'
  deviceList.setAttribute('id', 'other-devices')
  deviceList.addEventListener('click', async function (e) {
    e.preventDefault()
    showingList = !showingList
    if (showingList) {
      show(stationList)
      show(voucherButton)
      show(voucherElem)
      deviceList.style.backgroundColor = '#A593E0'
    } else {
      hide(stationList)
      deviceList.style.backgroundColor = ''
    }
    await loadAsyncData()
  })
}

init()

var showingList = false
var stationList = document.getElementById('station-list')
var errorElem = document.getElementById('error')
var resultElem = document.getElementById('result')

function prepareResult (res) {
  if (res.error) {
    console.log(res.error)
    errorElem.innerHTML = res.error
    show(errorElem)
    ubusError = true
  } else if (res && res.result[1]) return res.result[1]
  else return false
}

function authVoucher () {
  if (!userMac) return
  let mac
  if (showingList) {
    mac = document.getElementById('stations').value || userMac
  } else {
    mac = userMac
  }
  let voucher = voucherElem.value.toLowerCase()
  voucherElem.after(loader)
  show(loader)
  const authVoucherForm = {
    id: 99,
    jsonrpc: '2.0',
    method: 'call',
    params: [
      '00000000000000000000000000000000',
      'pirania',
      'auth_voucher',
      {
        voucher,
        mac
      }
    ]
  }
  fetch(url, {
    method: 'POST',
    body: JSON.stringify(authVoucherForm),
    headers: {
      'Access-Control-Allow-Origin': 'http://thisnode.info'
    }
  })
    .then(parseJSON)
    .then(prepareResult)
    .then(res => {
      hide(loader)
      show(voucherButton)
      if (res && res.success) {
        result.innerHTML = int[lang].success
        show(result)
        hide(errorElem)
        loadAsyncData()
      } else if (res && !res.success) {
        errorElem.innerHTML = int[lang].invalid
        show(errorElem)
      }
      voucherElem.value = ''
    })
    .catch(err => {
      console.log('UBUS error:', err)
      errorElem.innerHTML = err
      show(errorElem)
      ubusError = true
    })
}

function getIp () {
  return fetch('/cgi-bin/pirania/client_ip', {
    headers: {
      'Access-Control-Allow-Origin': 'http://thisnode.info'
    }
  })
    .then(async i => {
      const res = await i.json()
      userIp = res.ip
      userMac = res.mac
      userIsValid = res.valid
    })
    .catch(err => {
      console.log('Error fetching mac:', err)
      ubusError = true
    })
}

function getValidClients () {
  if (!ubusError) {
    const myDiv = document.getElementById('station-list')
    const exists = document.getElementById('stations')
    if (!exists) {
      const select = document.createElement('select')
      select.id = 'stations'
      myDiv.appendChild(select)
    }
  }
  return fetch(url, {
    method: 'POST',
    body: JSON.stringify(validGetClients),
    headers: {
      'Access-Control-Allow-Origin': 'http://thisnode.info'
    }
  })
    .then(parseJSON)
    .then(prepareResult)
    .then(res => {
      if (res && !ubusError) {
        document.getElementById('stations').innerHTML = ''
        res.clients.map(i => {
          const valid = validMacs.filter(valid => i.mac === valid).length > 0
          const node = document.createElement('option')
          let textnode = document.createTextNode('')
          if (userIp === i.ip) {
            userMac = i.mac
            node.selected = true
          }
          const isIp = userIp === i.ip ? '📱 ' : ''
          textnode.nodeValue = valid
            ? isIp + i.station + ' ✅'
            : isIp + i.station
          node.value = i.mac
          node.appendChild(textnode)
          return document.getElementById('stations').appendChild(node)
        })
      }
    })
    .catch(err => {
      console.log(int[lang].error, err)
      errorElem.innerHTML = int[lang].error
      show(errorElem)
      ubusError = true
    })
}

function getValidMacs () {
  fetch(url, {
    method: 'POST',
    body: JSON.stringify(validMacsForm),
    headers: {
      'Access-Control-Allow-Origin': 'http://thisnode.info'
    }
  })
    .then(parseJSON)
    .then(res => {
      if (res && res.result[1]) {
        validMacs = res.result[1].macs
        if (validMacs.length > 0) {
          getValidClients()
        }
      } else if (res.error) {
        console.log(res.error)
        errorElem.innerHTML = int[lang].error
        ubusError = true
      }
    })
    .catch(err => {
      console.log(int[lang].error, err)
      errorElem.innerHTML = int[lang].error
      ubusError = true
    })
}

voucherButton.addEventListener('click', function (e) {
  hide(voucherButton)
  show(loader)
  if (showingList) {
    e.preventDefault()
    authVoucher()
  }
})
