(function(){

    LDR.Config = (function(){
        function Config(){
            Object.assign(this, LDR.DefaultConfig);
            this.onConfigChange = {};
        }
        var fn = Config.prototype;

        fn.addCallback = function(key, callback){
            this.onConfigChange[key] = callback;
        };

        fn.set = function(key,value){
            var old_value = this[key];
            var new_value = value;
            this[key] = value;
            if(this.onConfigChange[key]){
                this.onConfigChange[key](old_value,new_value)
            }
            this.save();
        };

        fn.save = function(){
            var api = new LDR.API("/api/config/save");
            api.post(this);
        };

        fn.load = function(todo){
            var that = this;
            var api = new LDR.API("/api/config/load");
            api.post({timestamp:new Date - 0},function(data){
                data = typecast_config(data);
                Object.entries(data).forEach(function(entry){
                    var key = entry[0], value = entry[1];
                    if(typeof that[key] !== "function")
                        that[key] = value
                });
                todo();
            });
        };

        fn.startListener = function(todo){
            this.addCallback("view_mode",function(old_value,new_value){
                update(/mode_text.*/);
                subs.view.removeClass(old_value);
                subs.view.addClass(new_value);
            });

            this.addCallback("sort_mode",function(old_value,new_value){
                update(/mode_text.*/);
            });

            this.addCallback("current_font",function(old_value,new_value){
                setStyle("right_body", {fontSize: new_value + "px"});
            });

            this.addCallback("show_all",function(){
                update("show_all_button");
            });
        };


        return Config;
    })();

    // window.Config = new LDR.Config;
    // Config.startListener();

}).call(LDR);
