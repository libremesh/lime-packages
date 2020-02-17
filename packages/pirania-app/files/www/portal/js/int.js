const userLang = navigator.language || navigator.userLanguage
const lang = userLang.split('-')[0] || userLang || 'en'

const int = {
  pt: {
    selectVoucher: 'Entre o voucher',
    createNewVoucher: 'Criar novo voucher',
    createManyVouchers: 'Criar muitos vouchers',
    changeContent: 'Mudar o conteúdo',
    title: 'Título',
    welcome: 'Bem vindo',
    body: 'Texto principal',
    backgroundColor: 'Cor de fundo',
    rules: 'Regras da rede',
    listVouchers: 'Listar vouchers',
    success: 'Sucesso',
    error: 'Erro',
    invalid: 'Código incorreto',
    wrongPassword: 'Senha incorreta',
    name: 'Nome',
    days: 'Dias',
    numberOfVouchers: 'Número de vouchers',
    authenticated: 'Seu dispositivo está autenticado',
    wait: 'Aguarde',
    continue: 'Continuar',
    info: 'Mais informações',
  },
  es: {
    selectVoucher: 'Entre el voucher',
    createNewVoucher: 'Crear nuevo voucher',
    createManyVouchers: 'Crear muchos vouchers',
    changeContent: 'Cambiar el contenido',
    title: 'Título',
    welcome: 'Bienvenido',
    body: 'Texto principal',
    backgroundColor: 'Color de fondo',
    rules: 'Reglas de la rede',
    listVouchers: 'Listar vouchers',
    success: 'Sucesso',
    error: 'Erro',
    invalid: 'Código incorrecto',
    wrongPassword: 'Contraseña incorrecta',
    name: 'Nombre',
    days: 'Dias',
    numberOfVouchers: 'Cantidad de vouchers',
    authenticated: 'Tu dispositivo esta autenticado',
    wait: 'Espere',
    continue: 'Seguir',
    info: 'Mas informaciones',
  },
  en: {
    selectVoucher: 'Enter a voucher',
    createNewVoucher: 'Create new voucher',
    createManyVouchers: 'Create many vouchers',
    changeContent: 'Change content',
    title: 'Title',
    welcome: 'Welcome text',
    body: 'Main text',
    backgroundColor: 'Background color',
    rules: 'Network rules',
    listVouchers: 'List vouchers',
    success: 'Success',
    error: 'Error',
    invalid: 'Invalid voucher',
    wrongPassword: 'Wrong password',
    name: 'Nome',
    days: 'Dias',
    numberOfVouchers: 'Number of vouchers',
    authenticated: "You're device is authenticated!",
    wait: 'Wait',
    continue: 'Continue',
    info: 'More information',
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