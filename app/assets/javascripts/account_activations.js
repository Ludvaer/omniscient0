(function() {
  root = typeof exports !== "undefined" && exports !== null ? exports : this;
  root.ajaxify_link = function(link, response_area) {
    link.on("ajax:success", function(e, data, status, xhr) {
      response_area.html(data.html);
      if (data.redirect) {
        return Turbolinks.visit($('#redirect-to-user').attr('href'));
      }
    });
    return link.on("ajax:error", function(e, xhr, status, error) {
      return alert("Ajax request failed");
    });
  };
}).call(this);
