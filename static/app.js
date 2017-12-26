(function() {
  // use strict
  window.addEventListener('load', function() {
    var logo = document.querySelector('#logo');
    var x = -200, y = -200, dx = 10, dy = 10;
    logo.style.display = 'block';
    setInterval(function() {
      x += dx, y += dy;
      var pw = document.body.clientWidth - logo.width;
      var ph = Math.max.apply(null, [document.body.clientHeight, document.body.scrollHeight, document.documentElement.scrollHeight, document.documentElement.clientHeight]) - logo.width;
      if ((dx > 0 && x > pw) || (dx < 0 && x < 0)) dx = -dx;
      if ((dy > 0 && y > ph) || (dy < 0 && y < 0)) dy = -dy;
      logo.style.left = x + 'px', logo.style.top = y + 'px';
    }, 20);
  }, false);
})();

