
(function() {
  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  serializeForm = function(form) {
    var hash, i, item, len, ref;
    hash = {};
    ref = form.serializeArray();
    for (i = 0, len = ref.length; i < len; i++) {
      item = ref[i];
      hash[item.name] = item.value;
    }
    return hash;
  };

  root.sendShulte = function() {
    var data, method;
    data = serializeForm($('form'));
    method = 'post';
    if ($('input[name="_method"]').val()) {
      method = $('input[name="_method"]').val();
    }
    return $.ajax($('form').attr('action'), {
      type: method,
      dataType: 'json',
      data: data,
      error: function(jqXHR, textStatus, errorThrown) {
        alert("Ajax request failed");
        return show_start_button();
      },
      success: function(data, textStatus, jqXHR) {
        return $("#shulte-save-response").html(data.html);
      }
    });
  }
}).call(this);
