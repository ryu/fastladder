/* Event */
Event.observeWheel = function(el,callback){
    Event.observe(el,"wheel",function(e){
        Event.stop(e);
        var delta = e.deltaY > 0 ? 1 : -1;
        callback(delta);
    });
};


