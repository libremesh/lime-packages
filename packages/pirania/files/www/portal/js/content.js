let loader = document.createElement('div')
loader.className = 'lds-ring'
loader.appendChild(document.createElement('div'))
loader.appendChild(document.createElement('div'))
loader.appendChild(document.createElement('div'))
loader.appendChild(document.createElement('div'))

const show = elem => elem.classList.remove('hidden')
const hide = elem => (elem.className += ' hidden')

var nojsElem = document.getElementById('nojs')
if (nojsElem) {
  nojsElem.setAttribute('value', false)
}

var param = '?prev='
var prevUrl = window.location.search.split(param)[1]
if (prevUrl) {
  var prevElem = document.createElement('input')
  prevElem.setAttribute('value', prevUrl)
  prevElem.setAttribute('id', 'prev')
  prevElem.setAttribute('name', 'prev')
  document.getElementById('voucher').appendChild(prevElem)
}

let content = {
  backgroundColor: 'white',
  title: '',
  welcome: '',
  body: '',
  logo: '',
  rules: '',
  mediaUrl: ''
}

function getContent () {
  ubusFetch('pirania-app', 'read_content')
    .then(res => {
      content = res
      const { backgroundColor, title, welcome, body, logo, rules, mediaUrl } = content
      document.body.style.backgroundColor = backgroundColor
      const contentLogo = document.getElementById('content-logo')
      const contentTitle = document.getElementById('content-title')
      const contentWelcome = document.getElementById('content-welcome')
      const contentBody = document.getElementById('content-body')
      const contentRules = document.getElementById('content-rules')
      const contentMedia = document.getElementById('content-media')

      if (contentLogo) {
        show(contentLogo)
        contentLogo.src = logo
      }
      if (contentTitle) contentTitle.innerHTML = title
      if (contentWelcome) contentWelcome.innerHTML = welcome
      if (contentBody) contentBody.innerHTML = body
      if (contentRules) contentRules.innerHTML = rules
      if (contentMedia) {
        var mediaType = mediaUrl.split('.')[mediaUrl.split('.').length -1]
        if (mediaType === 'mp4' || mediaType === 'webm' || mediaType === 'avi') {
          var videoContainerElem = document.createElement('video')
          var videoElem = document.createElement('source')
          contentMedia.append(videoContainerElem)
          videoElem.setAttribute('src', mediaUrl)
          videoElem.setAttribute('type', 'video/'+mediaType)
          videoContainerElem.appendChild(videoElem)
        } else if (mediaType === 'jpg' || mediaType === 'png' || mediaType === 'jpeg' || mediaType === 'gif' || mediaType === 'svg') {
          var imageElem = document.createElement('img')
          contentMedia.append(imageElem)
          imageElem.setAttribute('src', mediaUrl)
          imageElem.setAttribute('type', 'image/'+mediaType)
        }
      }
    })
    .catch(err => {
      document.getElementById('error').innerHTML = int[lang].error
    })
}

getContent()
