$(document).on('click', '.print-btn', function () {
  let targetPrintElementID = $(this).attr("target-print") || 'printReport';
  printJS({
    printable: targetPrintElementID,
    type: 'html',
    maxWidth: 1240,
    targetStyles: ['*'],
    ignoreElements: ['printBtnId'],
    showModal: true,
    modalMessage: 'Подготовка данных на печать'
  });
})