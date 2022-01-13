$(document).on('submit', '#rptFormParams', function (e) {
    e.preventDefault();

    $('#modalProgress').modal('show');

    let url = $(this).attr('action');
    let formData = $(this).serialize();

    $.ajax({
      url: url,
      type: 'post',
      data: formData,
    }).done(function (res) {
      $('#modalProgress').modal('hide');
      $('#rptResult').html(res);
    }).fail(function (jqXHR, textStatus, error) {
      $('#modalProgress').modal('hide');
      alert("Открытие отчета: " + (jqXHR.responseText || 'При выполнении запроса'));
    });
});