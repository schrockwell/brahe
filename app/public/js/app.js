// App JS code goes here

$(function() {
  setInterval(function() {
    $.get({
      url: '/current',
      success: function(data) {
        console.log(data);
      }
    });
  }, 1000);
});