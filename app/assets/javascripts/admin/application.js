//= require jquery-2.1.1
//= require jquery-ui-1.10.4.custom.min
//= require jquery_ujs
//= require bootstrap
//= require bootstrap-select
//= require bootstrap-datepicker
//= require jquery.unveil
//= require imagesloaded.pkgd.min
//= require js.cookie
//= require admin/base
//= require admin/sortable_list
//= require admin/puzzle_assets
//= require admin/puzzles
//= require admin/packs
//= require admin/jobs


$(document).ready(function () {
    
    $('.datepicker').each(function(){

        var date = new Date($(this).val());
        var $picker = $(this);

        $picker.datepicker({format: 'D d M yyyy'}).on('changeDate', function ( e ) {
            date = $(e.currentTarget).datepicker('getDate');
            $picker.siblings('input[type=hidden]').val(date.getFullYear()+'-'+(date.getMonth()+1)+'-'+date.getDate());
        });

        $picker.on('change', function(e){
            var date = new Date($(this).val());
            if(date == "Invalid Date"){
                $picker.siblings('input[type=hidden]').val('');
            }
        });

        if ( !isNaN(date) ) {
            $picker.datepicker('update', date);
        }

    });

    $('.api-tester .check-click').each(function(){

        $(this).on('click', function(e){

            var loadWindow = true;
            var $apitester = $(this).closest('.api-tester');
            var test       = $apitester.data('test');
            var url;

            if(test == undefined) return true;

            if(test == 'dailypuzzle'){

                var date = $('.date', $apitester).val();
                if(date == '') return false;

                var password = $('.password', $apitester).val();

                url = $apitester.data('path') + '?date=' + date+'&password='+password;

            }else if(test == 'packlist'){

                url = $apitester.data('path');

            }

            if(loadWindow) window.open(url);
            e.preventDefault();

        });

    });

    $('.asset-thumbnails.modal-thumbs .thumbnail').on('click', function(e){

        img    = $(this).attr('data-image');
        $modal = $('.modal');
        $('img', $modal).attr('src', img);
        $('.modal-title', $modal).html($('.info', this).html());
        $modal.modal();
        e.preventDefault();

    });

    $('.image-panel .image.zoomable').on('click', function(e){

        img    = $('img', this).attr('src');
        $modal = $('.modal');
        $('img', $modal).attr('src', img);
        $('.modal-title', $modal).html('&nbsp;');
        $modal.modal();
        e.preventDefault();

    });

    $('img.unveil').each(function(){
        $(this).imagesLoaded().done( function( instance ) {
            $(instance.images[0].img).removeClass('unveil');
        });
    });
    $('img.unveil').unveil();

});


