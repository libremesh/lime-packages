let session = null
let uploadedLogo = null

var errorElem = document.getElementById('error')

Date.daysBetween = function( date1, date2 ) {   //Get 1 day in milliseconds   
  var one_day=1000*60*60*24    // Convert both dates to milliseconds
  var date1_ms = date1.getTime()   
  var date2_ms = date2.getTime()    // Calculate the difference in milliseconds  
  var difference_ms = date2_ms - date1_ms        // Convert back to days and return   
  return Math.round(difference_ms/one_day) 
} 
  

function xDaysFromNow (days) {
  let date = new Date()
  let newDate = date.setDate(date.getDate() + parseInt(days))
  return newDate.toString()
}

function makeid(length) {
  var text = ""
  var possible = "abcdefghijklmnopqrstuvwxyz0123456789"
  for (var i = 0; i < length; i++)
    text += possible.charAt(Math.floor(Math.random() * possible.length))
  return text
}

function compress(e) {
  const fileName = e.target.files[0].name
  const reader = new FileReader()
  reader.readAsDataURL(e.target.files[0])
  reader.onload = event => {
    const img = new Image()
    img.src = event.target.result
    img.onload = () => {
      const elem = document.createElement('canvas')
      const width = 50
      const scaleFactor = width / img.width
      elem.width = width
      elem.height = img.height * scaleFactor
      const ctx = elem.getContext('2d')
      ctx.drawImage(img, 0, 0, width, img.height * scaleFactor)              
      ctx.canvas.toBlob((blob) => {
        const file = new File([blob], fileName, {
            type: 'image/jpeg',
            lastModified: Date.now()
        })
      }, 'image/jpeg', 1)
      console.log(ctx.canvas.toDataURL("image/jpeg"))
      uploadedLogo = ctx.canvas.toDataURL("image/jpeg")
      document.getElementById("logo-upload").appendChild(elem)
    },
    reader.onerror = error => console.log(error)

  }
}

function createManyVouchers () {
  const createLoader = document.getElementById('voucher-create-loader')
  const key = document.getElementById('adminManyInputKey').value
  const days = document.getElementById('adminManyInputDays').value
  const numberVouchers = document.getElementById('adminManyInputVouchers').value
  const epoc = xDaysFromNow(days)
  const vouchers = []
  for (let index = 0; index < numberVouchers; index++) {
    vouchers.push({
      key: `${key}-${makeid(3)}`,
      voucher: makeid(8),
      epoc,
    })
  }
  console.log('VOUCHERS GO', JSON.stringify(vouchers))
  hide(errorElem)
  show(createLoader)
  ubusFetch('pirania', 'add_many_vouchers', { vouchers }, session)
    .then(res => {
      console.log('RESPONSE', res)
      if (res.success) {
        listVouchers()
        console.log('VOUCHERS SUCCESS', res.success)
        document.getElementById('adminManyInputKey').value = ''
        document.getElementById('adminManyInputDays').value  = 1
        document.getElementById('adminManyInputVouchers').value  = 1
        document.getElementById('many-result').innerHTML = 'Sucesso!'
      }
    })
    .catch(err => {
      console.log('Can find this error ', err)
      listVouchers()
      document.getElementById('adminManyInputKey').value = ''
      document.getElementById('adminManyInputDays').value  = 1
      document.getElementById('adminManyInputVouchers').value  = 1
      document.getElementById('many-result').innerHTML = 'Sucesso!'
      // show(errorElem)
      hide(createLoader)
    })
}

function removeVoucher (name) {
  ubusFetch('pirania', 'remove_voucher', { name }, session)
  .then(res => {
    console.log(res)
    listVouchers()
  })
  .catch(err => {
    console.log(err)
    show(errorElem)
  })
}

/* Needs to be implemented in shared-state */
// function renewVoucher (name) {
//   console.log(name, xDaysFromNow(30))
//   ubusFetch('pirania', 'renew_voucher', { name, date: xDaysFromNow(30) }, session)
//   .then(res => console.log(res))
//   .catch(err => {
//     console.log(err)
//     show(errorElem)
//   })
// }

function getVoucherName (name) {
  return name.split('-')[0]
}

function listVouchers () {
  let voucherList = document.getElementById("voucher-list")
  let listLoader = document.getElementById('voucher-list-loader')
  hide(errorElem)
  voucherList.innerHTML = ''
  show(listLoader)
  ubusFetch('pirania', 'list_vouchers', {}, session)
  .then(res => {
    const vouchers = res.vouchers
    // document.getElementById('voucher-list-button').style.display = 'none'
    vouchers
    .sort((a, b) => {
      if(parseInt(a.expires) > parseInt(b.expires)) { return -1; }
      if(parseInt(a.expires) < parseInt(b.expires)) { return 1; }
      return 0;
    })
    .sort((a, b) => {
      if(getVoucherName(a.name) < getVoucherName(b.name)) { return -1; }
      if(getVoucherName(a.name) > getVoucherName(b.name)) { return 1; }
      return 0;
    })
    .map(v => {
      const date = new Date (parseInt(v.expires))
      const dateDiff = Date.daysBetween(new Date(), date)
      let container = document.createElement('div')
      container.className = 'voucher-item'
      let vQuantity = document.createElement('div')
      vQuantity.className = 'voucher-item-mq'
      vQuantity.innerHTML = v.macs.length > 0 ? v.macs.length : ''
      container.appendChild(vQuantity)
      let name = document.createElement('div')
      name.className = 'voucher-item-name'
      name.innerHTML = v.name
      container.appendChild(name)
      let voucher = document.createElement('div')
      voucher.className = 'voucher-item-voucher'
      voucher.innerHTML = v.voucher
      container.appendChild(voucher)
      /* Needs to be implemented in shared-state */
      // let renew = document.createElementNS("http://www.w3.org/2000/svg", "svg")
      // renew.setAttribute ("viewBox", "0 0 32 32" )
      // renew.setAttribute ("stroke", "currentcolor" )
      // renew.setAttribute ("stroke-linecap", "round" )
      // renew.setAttribute ("stroke-linejoin", "round" )
      // renew.setAttribute ("stroke-width", "2" )
      // renew.setAttribute ("fill", "none" )
      // renew.className = 'voucher-item-renew'
      // renew.onclick = () => renewVoucher(v.name)
      // let renewPath = document.createElementNS("http://www.w3.org/2000/svg", "path")
      // renewPath.setAttribute('d', 'M29 16 C29 22 24 29 16 29 8 29 3 22 3 16 3 10 8 3 16 3 21 3 25 6 27 9 M20 10 L27 9 28 2')
      // renew.appendChild(renewPath)
      // container.appendChild(renew)
      let remove = document.createElementNS("http://www.w3.org/2000/svg", "svg")
      remove.setAttribute ("viewBox", "0 0 32 32" )
      remove.setAttribute ("stroke", "currentcolor" )
      remove.setAttribute ("stroke-linecap", "round" )
      remove.setAttribute ("stroke-linejoin", "round" )
      remove.setAttribute ("stroke-width", "2" )
      remove.setAttribute ("fill", "none" )
      remove.className = 'voucher-item-remove'
      remove.onclick = () => removeVoucher(v.name)
      let removePath = document.createElementNS("http://www.w3.org/2000/svg", "path")
      removePath.setAttribute('d', 'M28 6 L6 6 8 30 24 30 26 6 4 6 M16 12 L16 24 M21 12 L20 24 M11 12 L12 24 M12 6 L13 2 19 2 20 6')
      remove.appendChild(removePath)
      container.appendChild(remove)
      let expires = document.createElement('div')
      expires.className = 'voucher-item-expires'
      expires.innerHTML = dateDiff > 0 ? dateDiff +' '+ int[lang].days : 0
      container.appendChild(expires)
      let macs = document.createElement('div')
      macs.innerHTML = v.macs.toString()
      macs.className = 'voucher-item-macs'
      listLoader.className = 'hidden'
      container.appendChild(macs)
      voucherList.appendChild(container)
      document.getElementById('voucher-list-button').classList.remove('hidden')
    })
  })
  .catch(err => {
    console.log(err)
    hide(listLoader)
    show(document.getElementById('voucher-list-button'))
    errorElem.innerHTML = int[lang].error
    show(errorElem)
  })
}

function updateContent () {
  const backgroundColor = document.getElementById('adminInputBackground').value
  const title = document.getElementById('adminInputTitle').value
  const welcome = document.getElementById('adminInputWelcome').value
  const body = document.getElementById('adminInputBody').value
  let logo = uploadedLogo || content.logo
  ubusFetch(
    'pirania-app',
    'write_content',
    {
      backgroundColor,
      title,
      welcome,
      body,
      logo,
    },
    session
  )
  .then(res => {
    content = res
    const { backgroundColor, title, welcome, body, logo } = content
    document.body.style.backgroundColor = backgroundColor
    const contentLogo = document.getElementById('content-logo')
    const contentTitle = document.getElementById('content-title')
    const contentWelcome = document.getElementById('content-welcome')
    const contentBody = document.getElementById('content-body')
    if (contentLogo) contentLogo.src = logo
    if (contentTitle) contentTitle.innerHTML = title
    if (contentWelcome) contentWelcome.innerHTML = welcome
    if (contentBody) contentBody.innerHTML = body
  })
  .catch(err => {
    errorElem.innerHTML = int[lang].error
    show(errorElem)
  })
}

function adminAuth () {
  const password = document.getElementById('adminInput').value
  ubusFetch(
    'session',
    'login',
    {
      username: 'root',
      password,
      timeout: 5000,
    }
  )
  .then(res => {
    hide(errorElem)
    session = res.ubus_rpc_session
    document.querySelector('.admin-login').style.display = 'none'
    document.querySelector('#tabs').classList.remove('hidden')
    const adminContent = document.querySelector('.admin-content')
    const { backgroundColor, title, welcome, body } = content
    document.getElementById('adminInputTitle').value = title
    document.getElementById('adminInputWelcome').value = welcome
    document.getElementById('adminInputBody').value = body
    document.getElementById('adminInputBackground').value = backgroundColor
    listVouchers()
  })
  .catch(err => {
    console.log(err)
    show(errorElem)
    errorElem.innerHTML = int[lang].wrongPassword
  })
}

document.getElementById("logo-file").addEventListener("change", function (event) {
  compress(event)
})