/*
 EventDispatcher
*/
var Event = {};
Event.list = [];
//Event.sweep_queue = [];
Event.sweep = function(){
	var q = Event.list;
	for(var i=0;i<q.length;i++){
		try{
			removeEvent.apply(this,q[i]);
			q[i] = null;
		} catch(e){
			// alert(e)
		}
	}
};
Event.observe = addEvent;
Event.stop = function(e){
	Event.stopAction(e);
	Event.stopEvent(e);
};
Event.stopAction = function(e){
	e.preventDefault();
};
Event.stopEvent = function(e){
	e.stopPropagation();
};
Event.pointerX = function(event) {
	return event.pageX;
};
Event.pointerY = function(event){
	return event.pageY;
};
Event.cancelFlag = {};
Event.cancelNext = function(type){
	Event.cancelFlag[type] = true;
};

Event.userDefined = {
	wheeldown: function(obj, evType, fn, useCapture){
		var callback = function(e){
			if(e.deltaY > 0){
				fn(e, 1);
			}
		};
		addEvent(obj, 'wheel', callback, useCapture);
	},
	wheelup: function(obj, evType, fn, useCapture){
		var callback = function(e){
			if(e.deltaY < 0){
				fn(e, -1);
			}
		};
		addEvent(obj, 'wheel', callback, useCapture);
	}
};

window.onunload = Event.sweep;
function addEvent(obj, evType, fn, useCapture){
	if(Event.userDefined.hasOwnProperty(evType)){
		return Event.userDefined[evType].apply(null, arguments);
	}
	Event.list.push(arguments);
	obj.addEventListener(evType, fn, useCapture);
	var args = arguments;
	return function(){
		removeEvent.apply(this,args);
	}
}
function removeEvent(obj, evType, fn, useCapture){
	obj.removeEventListener(evType, fn, useCapture);
	return true;
}
class Trigger {
	constructor(type){
		this._type = null;
		this.event_list = [];
		this.enable = true;
		this.type = type;
	}
	apply(target){
		if(!target){
			target = document.body;
		} else {
			target = _$(target)
		}
		addEvent(target, this.type, function(e){
			var element = e.target;
			var args = Array.prototype.slice(arguments);
			args[0] = e;
			if(Event.cancelFlag[e.type] == true){
				Event.cancelFlag[e.type] = false;
				return;
			}
			/*
			this.event_list.forEach(function(pair){
				this.enable && pair[1].apply(element,args) && pair[2].apply(element,args)
			},this)
			*/
			var pair;
			for(var i=0;i<this.event_list.length;i++){
				pair = this.event_list[i];
				this.enable && pair[1].apply(element,args) && pair[2].apply(element,args);
			}
			element = null;
			e = null;
		}.bind(this))
		this.destroy();
	}
	destroy(){}
	add(trigger, callback){
		var expression;
		if(isString(trigger)){
			expression = cssTester(trigger);
		} else {
			expression = trigger;
		}
		this.event_list.push([
			trigger, expression, callback
		]);
		return this
	}
	remove(trigger){
		this.event_list = this.event_list.reject(function(pair){
			return pair[0] == trigger;
		});
		return this;
	}
	toggle(state){
		this.enable = arguments.length ? !this.enable : state;
		return this.enable;
	}
}
Trigger.create = function(type){
	return new Trigger(type)
};
