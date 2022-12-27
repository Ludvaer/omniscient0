(function() {
    var root, serializeForm;

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

  root.init_users_form = function() {
    $('#user-submit').hide();
    return $('#sign-up-button').show();
  };

  root.encryptsignup = function() {
    var data, encrypted1, encrypted2, hashed1, hashed2, hmac, method, name_as_salt, publicKey1, salt, uname;
    $('#sign-up-button').hide();
    uname = $("#user_name").val();
    if ((uname != null)) {
      name_as_salt = uname.trim().replace(/ +/g, " ").toLowerCase();
    }
    data = serializeForm($('form'));
    if ($('#user_password').length) {
      salt = $("#salt").val();
      hmac = forge.hmac.create();
      hmac.start('sha256', name_as_salt);
      hmac.update($('#user_password').val());
      hashed1 = hmac.digest().toHex();
      publicKey1 = forge.pki.publicKeyFromPem($("#publickey").val());
      encrypted1 = forge.util.bytesToHex(publicKey1.encrypt(hashed1 + '|' + salt));
      delete data['user[password]'];
      data['user[password_encrypted]'] = encrypted1;
    }
    if ($('#old_password').length) {
      salt = $("#salt").val();
      hmac = forge.hmac.create();
      hmac.start('sha256', name_as_salt);
      hmac.update($('#old_password').val());
      hashed2 = hmac.digest().toHex();
      publicKey1 = forge.pki.publicKeyFromPem($("#publickey").val());
      encrypted2 = forge.util.bytesToHex(publicKey1.encrypt(hashed2 + '|' + salt));
      delete data['user[old_password]'];
      data['user[old_password_encrypted]'] = encrypted2;
    }
    if ($('#user_password_confirmation').length) {
      salt = $("#salt").val();
      hmac = forge.hmac.create();
      hmac.start('sha256', name_as_salt);
      hmac.update($('#user_password_confirmation').val());
      hashed2 = hmac.digest().toHex();
      publicKey1 = forge.pki.publicKeyFromPem($("#publickey").val());
      encrypted2 = forge.util.bytesToHex(publicKey1.encrypt(hashed2 + '|' + salt));
      delete data['user[password_confirmation]'];
      data['user[password_confirmation_encrypted]'] = encrypted2;
    }
    delete data['salt'];
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
        return $('#sign-up-button').show();
      },
      success: function(data, textStatus, jqXHR) {
        $("#sign-up-response").html(data.html);
        if (data.redirect) {
          return Turbolinks.visit($('#redirect-to-user').attr('href'));
        } else {
          $('#sign-up-button').show();
          return $('#user-submit').hide();
        }
      }
    });
  };
}).call(this);
