
$(document).ready(function () {

    if($('.jobs-index').length > 0){
        window.jobsInterval = startInterval(1000);
    }

});

function startInterval(timeout){

    return setInterval(function(){
        
        $.ajax({
          url: document.location
        }).done(function(data) {
            $('.jobs-index').html($(data).find('.jobs-index').html());
            newTimeout = $('.jobs-index tbody tr').length == 0 ? 5000 : 1000;
            if(newTimeout != timeout){
                clearInterval(window.jobsInterval);
                window.jobsInterval = startInterval(newTimeout);
            }
        });

    }, timeout);

}