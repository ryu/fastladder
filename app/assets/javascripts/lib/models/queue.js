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
			(function processQueue(){
				var count = 0;
				while(count < step){
					var f = queue.shift();
					typeof f === "function" && f();
					count++;
				}
				if(queue.length){
					processQueue.later(interval)()
				}
			}).later(interval)();
			//TODO あとでlasterは消す
		}
	}
	LDR.Queue = Queue;
}).call(LDR);
