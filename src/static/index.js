// pull in desired CSS/SASS files
require('./styles/main.scss');

// inject bundled Elm app into div#main
var Elm = require('../elm/Main');

var value = localStorage.getItem('JWTPORT');

var app = Elm.Main.embed(document.getElementById('main'), value);

// app.ports.writeToLocalStorage.subscribe(function(value) {
//   localStorage.setItem('JWTPORT', value);
// });

app.ports.requestLocalStorage.subscribe(function() {
  var value = localStorage.getItem('JWTPORT');
  app.ports.localStorage.send(value);
});

app.ports.writeToPortPort.subscribe(function([cmdtype, value]) {
  switch (cmdtype) {
    case 'WriteToLocalStorage':
      localStorage.setItem('JWTPORT', value);
      break;
    default:
      throw Error('wat?');
  }
});
