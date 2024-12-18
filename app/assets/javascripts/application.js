// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//Dir["forge"].each {|file| require file }
//= require forge/md
//= require forge/md5
//= require forge/cipherModes
//= require forge/cipher
//= require forge/aes
//= require forge/sha256
//= require forge/sha512
//= require forge/util
//= require forge/prng
//= require forge/random
//= require forge/pem
//= require forge/asn1
//= require forge/jsbn
//= require forge/rsa
//= require forge/oids
//= require forge/x509
//= require forge/pki
//= require forge/hmac
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require wanakana.min
//= require_tree .
//= stub 'shultes'
//= stub 'pick_word_in_sets'
//= stub 'test_page'

function unique(a) {
  return [...new Set(a)];
}
(function() {
  let root = typeof exports !== "undefined" && exports !== null ? exports : this;
  root.INIT_FORMS = false;
  root.formModels = {};
  root.initialized = {};
  root.unique = unique;
  }).call(this);
