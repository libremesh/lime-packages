const url = 'http://thisnode.info/ubus'
let ubusError = false

function parseJSON(response) {
  return response.json()
}

const ubusFetch = (call, action, params, session) => new Promise ((resolve, reject) => {
  const form = {
    id: 99,
    jsonrpc: '2.0',
    method: 'call',
    params:[
      session || '00000000000000000000000000000000',
      call,
      action,
      params || {},
    ]
  }
  fetch(url, {
    method: 'POST',
    body: JSON.stringify(form),
    headers: {
      'Access-Control-Allow-Origin': 'http://thisnode.info'
    },
  })
  .then(parseJSON)
  .then((res) => {
    if (res && res.result[1]) {
      resolve(res.result[1])
    } else {
      ubusError = true
      reject(int[lang].error)
    }
  })
  .catch((err) => {
    console.log('Ubus error ', err)
    ubusError = true
    reject(int[lang].error)
  })
})