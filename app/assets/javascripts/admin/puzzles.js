$(document).ready(function () {

    $('.nav-tabs li a').on('click', function(e){
        var code = $(this).data('code');
        $('.tab-pane').removeClass('active');
        $('.nav-tabs li').removeClass('active');

        $('.tab-pane[data-code='+code+']').addClass('active');
        $(this).closest('li').addClass('active');

    });

    var months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
    ];

    $('td[data-timestamp]').each(function(){
        var d = new Date(parseInt($(this).attr('data-timestamp')));
        $(this).html(d.getDate()+' '+months[d.getMonth()]+' '+d.getFullYear()+' '+d.getHours()+':'+('0'+d.getMinutes()).slice(-2))
    });

    if($('#move-puzzle-modal').length){

        var $modal = $('#move-puzzle-modal');
        var $form = $('.move-form', $modal);
        var infoUrl = $modal.attr('data-info-url');
        var moveUrl = $modal.attr('data-move-url');
        var puzzles = [];

        $('.pack-select', $modal).on('change', function(e){

            var val = $(this).val();
            var url = infoUrl.replace('ID', val);

            $modal.removeClass('pack-chosen');
            $modal.removeClass('action-chosen');

            $('.target-select option', $modal).each(function(){
                if($(this).attr('value') != '') $(this).remove();
            });

            $('.action-select', $modal).val('');

            if(val != ''){
                $.get(url, function(data){

                    $('select', $modal).prop('disabled', false);

                    if(data.puzzles.length > 0){
                        
                        for(p in data.puzzles){

                            var puzzle = data.puzzles[p];
                            var option = $('<option value="'+puzzle.id+'">'+puzzle.image_id+'</option>');
                            $('.target-select', $modal).append(option);
                            
                        }

                        $modal.addClass('pack-chosen');
                    }
                });
                $('select', $modal).prop('disabled', true);
            }

        });

        $('.action-select', $modal).on('change', function(e){
            var val = $(this).val();
            $modal.toggleClass('action-chosen', (val != ''));
        });

        $('.target-select', $modal).on('change', function(e){
            var val = $(this).val();
            $modal.toggleClass('target-chosen', (val != ''));
        });

        $('.move-puzzle-btn', $modal).on('click', function(e){

            $.ajax({
                url: moveUrl,
                type: 'post',
                data: $form.serialize(),
                success: function(data){
                    window.location.reload();
                }
            });

            $('select', $modal).prop('disabled', true);
            $('.move-puzzle-btn', $modal).html('Moving ...');

            e.preventDefault();

        });

    }

});