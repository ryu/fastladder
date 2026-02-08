(function(){
	class Queue {
		constructor() {
			this.queue = [];
			this.step = 1;
			this.interval = 100;
		}

		push(f) {
			this.queue.push(f);
		}

		exec() {
			var queue = this.queue;
			var step = this.step;
			var interval = this.interval;
			(function(){
				var self = arguments.callee;
				var count = 0;
				while(count < step){
					var f = queue.shift();
					isFunction(f) && f();
					count++;
				}
				if(queue.length){
					self.later(interval)()
				}
			}).later(interval)();
			//TODO あとでlasterは消す
		}
	}
	LDR.Queue = Queue;
}).call(LDR);
