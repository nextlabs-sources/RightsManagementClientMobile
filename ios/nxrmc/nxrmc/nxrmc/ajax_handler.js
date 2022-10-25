

var s_ajaxListener = new Object();
s_ajaxListener.tempOpen = XMLHttpRequest.prototype.open;
XMLHttpRequest.prototype.open = function() {
        this.addEventListener('readystatechange', function() {
              var result = eval("(" + this.responseText + ")");
              if (result.statusCode == 200 && result.message == "Authorized") {
                  var temp = this.responseText;
                  window.stop();
                  window.webkit.messageHandlers.observe.postMessage(temp);
              }
        }, false);
        s_ajaxListener.tempOpen.apply(this, arguments);
}