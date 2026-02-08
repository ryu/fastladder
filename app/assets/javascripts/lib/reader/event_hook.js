// Hook
(function(){
    /*
     Hook
    */
    class Hook {
        constructor(){
            this.callbacks = [];
            this.isHook = true;
        }
        add(f){
            this.callbacks.push(f)
        }
        exec(){
            var args = arguments;
            this.callbacks.forEach(function(f){
                typeof f === "function" && f.apply(null,args)
            })
        }
        clear(){
            this.callbacks = []
        }
    }

    class EventTrigger {
        constructor(){
            var points = Array.from(arguments);
            var triggers = {};
            points.forEach(function(name){
                var hook_name = name.toLowerCase();
                triggers[hook_name] = new Hook;
            });
            this.triggers = triggers;
        }
        add_trigger(point, callback){
            var point = point.toLowerCase();
            if(this.triggers.hasOwnProperty(point)){
                this.triggers[point].add(callback)
            }
        }
        call_trigger(point, args){
            point = point.toLowerCase();
            if(this.triggers.hasOwnProperty(point)){
                this.triggers[point].exec(args);
            }
        }
    }
    LDR.EventTrigger = EventTrigger;
}).call(LDR);

