$(function() {

  $('#not_started').change(function() {
    if ($('#not_started').prop("checked")) {
      $('#date_started').prop("disabled", true);
      $('#date_started').val("");
      $('#not_completed').prop("disabled", true);
      $('#date_completed').prop("disabled", true);
      $('#date_completed').val("");
    } else {
      $('#date_started').prop("disabled", false);
      $('#not_completed').prop("disabled", false);
      $('#date_completed').prop("disabled", false);
    }
  });

  $('#not_completed').change(function() {
    if ($('#not_completed').prop("checked")) {
      $('#date_completed').prop("disabled", true);
      $('#date_completed').val("");
    } else {
      $('#date_completed').prop("disabled", false);
    }
  });

});