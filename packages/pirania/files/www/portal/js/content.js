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
  prevElem.setAttribute('class', 'hidden')
  document.getElementById('form').appendChild(prevElem)
}

let content = {
  backgroundColor: 'white',
  title: '',
  main_text: '',
  logo: '',
  link_title: '',
  link_URL: ''
}

function getContent () {
  ubusFetch('pirania', 'get_portal_page_content')
    .then(res => {
      content = res;
      const { background_color, title, main_text, logo, link_title, link_url } = content;
      document.body.style.backgroundColor = background_color;
      const contentLogo = document.getElementById('content-logo')
      const contentTitle = document.getElementById('content-title')
      const contentMainText = document.getElementById('content-main-text');
      const contentLink = document.getElementById('content-link');

      if (contentLogo) {
        show(contentLogo);
        contentLogo.src = logo;
      }
      if (contentTitle) contentTitle.innerHTML = title;
      if (contentMainText) contentMainText.innerHTML = main_text;
      if (contentLink && link_title && link_url) {
        var sectionTitle = document.getElementById('content-link-title');
        show(sectionTitle);
        var link_elem = document.createElement('a');
        link_elem.innerHTML = link_title;
        link_elem.setAttribute('href', link_url);
        contentLink.appendChild(link_elem);
      }
    })
    .catch(err => {
      document.getElementById('error').innerHTML = int[lang].error
    })
}

getContent()
