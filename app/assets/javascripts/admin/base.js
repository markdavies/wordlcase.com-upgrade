$(document).ready(function () {

    // Tooltips
    var tooltipElements = [
        'td.actions ul li a'
    ].join('\n');

    $(tooltipElements).tooltip();

    // Save and edit functionality
    $('a.save-edit:not(.disabled)').on('click', function ( e ) {
        e.preventDefault();
        var $form  = $(this).closest('form'),
            action = $form.attr('action');
        $form.attr('action', action + '?edit=true').submit();
    });

    // Admin panel
    var $adminPanel = $('.admin-panel');
    $adminPanel.on('click', '.panel-heading button', function () {

        var attachment = $(this).data('attachment');
        var variant = $(this).data('variant');
        var panelType = $(this).data('panel-type');

        $(this).closest('.admin-panel').find('.panel-body *[data-variant="' + variant + '"]')
            .show().siblings().hide();
        $(this).closest('.admin-panel').find('.panel-footer *[data-attachment="' + attachment + '"]')
            .show().siblings().hide();

        $('.active', $(this).closest('.admin-panel')).removeClass('active');
        $(this).addClass('active');
        
        $(this).closest('.admin-panel').attr('data-panel-type', panelType);

    });
    
    
    $adminPanel.each(function(){
        $(this).find('button').first().addClass('active');
        $(this).find('.panel-body > *').first().show();
        $(this).find('.panel-footer > *').first().show();
    });

    var sortables = [];
    $('.sortable-list').each(function(){
        sortables.push(new SortableList($(this)));
    });

    // Sir Trevor gallery uploads

    assetHost = typeof(assetHost) == 'undefined' ? '' : assetHost;

    $('.image_json').each(function(){

        var type = $(this).data('type');

        SirTrevor.setDefaults({
            uploadUrl: '/admin/'+type+'/images'
        });

        SirTrevor.setBlockOptions('Gallery', {
            assetHost: assetHost
        });
        
        var editor = new SirTrevor.Editor({ 
            el: $(this), 
            blockTypes: [ 'Gallery' ],
            blockLimit: 1, 
            defaultType: 'Gallery'
        });

        editor.scrollTo = function ( element ) {
            $('html, body').animate({ scrollTop: element.offset().top }, 300, "linear");
        }

    });

    // fix for mobile drop downs
    $('[data-toggle=dropdown]').each(function() {
     this.addEventListener('click', function() {}, false);
    });

});




