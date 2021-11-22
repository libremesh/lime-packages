const userLang = navigator.language || navigator.userLanguage
const lang = userLang.split('-')[0] || userLang || 'en'

const int = {
  pt: {
    selectVoucher: 'Entre o voucher',
    invalid: 'Código incorreto',
    authenticated: 'Seu dispositivo está autenticado',
    wait: 'Aguarde',
    continue: 'Continuar',
  },
  es: {
    selectVoucher: 'Entre el voucher',
    invalid: 'Código incorrecto',
    authenticated: 'Tu dispositivo esta autenticado',
    wait: 'Espere',
    continue: 'Seguir',
  },
  en: {
    selectVoucher: 'Enter a voucher',
    invalid: 'Invalid voucher',
    authenticated: "You're device is authenticated!",
    wait: 'Wait',
    continue: 'Continue',
  }
}

Object.keys(int[lang]).map(text => {
  Array.from(document.getElementsByClassName(`int-${text}`)).map(
    element => {
      if (element.tagName === 'INPUT') {
        element.value = int[lang][text]
      } else {
        element.innerHTML = int[lang][text]
      }
    }
  )
})
