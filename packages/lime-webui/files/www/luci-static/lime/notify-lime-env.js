document.addEventListener("DOMContentLoaded", function() {
  var alert_message, text;
  if((document.location.pathname.indexOf('cgi-bin/luci/admin') >= 0) && (document.location.pathname.indexOf('status') < 0)) {
    alert_message = document.createElement('div');
    alert_message.classList.add('lime-alert')
    text = document.createTextNode('Changes made in this section may be overwritten by lime-config.');

    alert_message.appendChild(text);
    document.getElementsByTagName('header')[0].appendChild(alert_message);
  }
});
