
var SortableList = function($t){

  var $target = $t;
  var $sortable = $('.sortable', $target);
  var $addButton = $('.sortable-add-button', $target);
  var $addSelect = $('.sortable-add-select', $target);

  var $formSort = $('.position_form_sortable');
  var $formSelect = $('.position_form_select');

  var $selectPositions = $('select.position', $target);
  var $fieldPositions = $('.sortable-positions', $target);
  var $fieldIdList = $('.sortable-id-list', $target);

  var klass = $target.data('class');
  var constant = $target.data('constant');
  var parent = $target.data('parent');
  var template = $target.data('template');
  var submittable = $target.data('submittable');
  var handle = $target.data('handle');
  var ids = [];
  
  function init(){
    
    setSortable();
    setDropDowns()
    setAddable();
    setItemClicks();
    updateIds();

  }

  function setSortable(){

    var config = {
      helper: function(e, tr){
          var $originals = tr.children();
          var $helper = tr.clone();
          $('.actions', $helper).empty();
          $helper.children().each(function(index)
          {
            // Set helper cell sizes to match the original sizes
            $(this).width($originals.eq(index).width());
          });
          return $helper;
      },
      update: function( event, ui ) {
        updateIds(true);

      }
    };

    if(handle){
      config.handle = handle;
    }

    $sortable.sortable(config);

  }

  function setDropDowns () {
    $selectPositions.on('change', function () {
        var $sortItem = $(this).closest('.sort-item');
        $formSelect.find('input[name=id]').val($sortItem.data('id'));
        $formSelect.find('input[name=position]').val($(this).val());
        $formSelect.find('input[name=klass]').val(constant);
        $formSelect.submit();
    });
  }

  function setAddable(){

    $addButton.on('click', function(e){

      var $option = $('option:selected', $addSelect);
      if($option.attr('disabled') == 'disabled') return false;

      var data = $option.data();
      var $item = $(template);
      $item.attr('data-id', data.id);
      $('.item-thumbnail', $item).html(data.thumbnail);
      $('.item-caption', $item).html(data.caption);

      $sortable.append($item);

      updateList();
      updateAddable();
      updateIds();

      e.preventDefault();

    });

  }

  function setItemClicks(){

    $sortable.on('click', function(e){

      if($(e.target).hasClass('remove-button')){
        $(e.target).closest('.sort-item').remove();

        updateIds();
        updateList();
        updateAddable();
        
        e.preventDefault();
      }

    });

  }

  function updateIds(submit){

    ids = [];
    var $items = $('.sort-item', $sortable);

    $items.each(function(){
      ids.push($(this).data('id'));
    });
    

    if(submittable && submit){

      $('input[name=positions]', $formSort).val(ids.join(','));
      $('input[name=klass]', $formSort).val(constant);
      $formSort.submit();

    }else{
       
      $fieldPositions.val(ids.join(','));
      $fieldIdList.html('');
      for(var i in ids){
        $fieldIdList.append($('<input type="hidden" name="'+parent+'['+klass+'_ids][]" value="'+ids[i]+'" />'));
      }

    }

  }

  function updateList(){

    var $items = $('.sort-item', $sortable);
    $('.no-items', $sortable).toggleClass('hide', !($items.size() == 0));

  }

  function updateAddable(){
    if($addSelect.size() == 0) return false;

    $('option', $addSelect).prop('disabled', false);

    var $items = $('.sort-item', $sortable);
    $items.each(function(){
        var id = $(this).data('id');
        $('option[data-id='+id+']', $addSelect).prop('disabled', true);
    });

  }

  init();

};


