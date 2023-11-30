
$(document).ready(function () {

    $('.bulk-create-packs .dropdown-menu a').on('click', function(e){
        var number = parseInt($(this).attr('data-number'));
        var type = $(this).attr('data-type');
        return window.confirm('Really create '+number+' '+type+' pack'+(number > 1 ? 's' : '')+'?');

    });

    $('.confirm-action').on('click', function(e){
        var confirm = window.confirm($(this).attr('data-confirm-msg'));
        if(!confirm){
            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();
        }
        return confirm;
    });

    $('.selective-sync-form .update-selective-sync').on('click', function(e){
        
        var $form = $('.selective-sync-form');
        var content = $form.find('input[name=content]:checked').val();
        var language = $form.find('input[name="language[]"]:checked').map(function(){
            return $(this).val();
        }).toArray();
        var data = {content: content, language: language};

        Cookies.set('sync_prefs', JSON.stringify(data));

    });

    $('.bulk-select').on('click', function(e){
        checkPackBulkSelects();
    });

    $('.bulk-actions a').on('click', function(e){
        
        var ids = getBulkSelectIds().join(',');

        if($(this).hasClass('selective-sync')){
            $('.selective-sync-form input[name=ids]').val(ids);

        }else{

            document.location.href = $(this).attr('href') + '?ids='+ids;
            e.preventDefault();

        }

    });

    $(window).on('keydown', function(e){

        if(e.keyCode == 13 && $('.selective-sync-form').is(':visible')){
            $('.selective-sync-form').submit();
        }
        
    });

    var pings = [];

    $('.pack-actions *[data-ping]').each(function(){
        var ping = $(this).attr('data-ping');
        if(ping != '') pings.push(ping);
    });

    if(pings.length > 0){

        var pingUrl = $('.pack-actions').attr('data-ping-url');
        var pingInterval = setInterval(function(){
            $.get(pingUrl, function(data){
                for(p in pings){
                    if(data[pings[p]] == false){
                        clearInterval(pingInterval)
                        window.location.reload(false);
                    }
                }
            })

        }, 2000);

    }

    $('.quality-load-link').on('click', function(e){

        var $self = $(this);

        $.ajax({
            url: $(this).attr('href'),
            type: 'get',
            success: function(data){
                var html = '';

                for(d in data.quality){
                    var q = data.quality[d];
                    var level = 'default';

                    if(q !== false){

                        if(q >= data.quality_threshold_2){
                            level = 'danger'
                        }else if(q >= data.quality_threshold_1){
                            level = 'warning'
                        }

                        html += "<span class='label label-"+level+"'>"+q+"</span>";
                    }

                }

                $self.replaceWith(html);
            }
        });

        e.preventDefault();
        e.stopPropagation();

    });

});

function checkPackBulkSelects(){

    var ids = getBulkSelectIds();
    $('.bulk-actions').toggleClass('reveal', ids.length > 0);

}

function getBulkSelectIds(){

    var ids = [];

    $('.bulk-select').each(function(e){
        if($(this).is(':checked')){
            ids.push($(this).attr('value'));
        }
    });

    return ids;
}