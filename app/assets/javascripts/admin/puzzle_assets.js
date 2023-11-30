$(document).ready(function () {

  var $month = $('.date-changer.month');
  var $year = $('.date-changer.year');

  $('.month-enum').on('click', function(e){

    var dir = $(this).hasClass('prev') ? 'prev' : 'next';
    var nextMonth = dir == 'prev' ? $(':selected', $month).prev() : $(':selected', $month).next();
    var nextYear = dir == 'prev' ? $(':selected', $year).prev() : $(':selected', $year).next();

    if(nextMonth.size()){
      $month.val(nextMonth.val());
      $('.date-changer.month').trigger('change');
    }else if (nextYear.size()){
      $year.val(nextYear.val());
      $('.date-changer.year').trigger('change');
    }

    e.preventDefault();

  });

  $('.new-asset-button').on('click', function(e){

    window.location.href = $(this).attr('href') + '?month=' + $('#month').val() + '&year=' + $('#year').val();
    e.preventDefault();

  });

  $('.date-changer').on('change', function(e){
    $(this).closest('form').submit();
    e.preventDefault();

  });

});