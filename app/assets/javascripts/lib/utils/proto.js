/*
 Prototype拡張
 Phase 6B: 使用頻度が高く置換コストが高いメソッドを残す
*/

// 簡易テンプレート (32箇所で使用)
String.prototype.fill  = function(){
	var param = {};
	Array.from(arguments).forEach(function(o){
		Object.assign(param,o)
	})
	return this.replace(/\[\[(.*?)\]\]/g,function($0,$1){
		var key = $1.trim();
		return param[key] ? param[key] : "";
	})
};

// documentFragmentに変換 (7箇所で使用)
Array.prototype.toDF = function(){
	var nodelist = this;
	var df = document.createDocumentFragment();
	nodelist.forEach(function(node){
		df.appendChild(node)
	});
	return df;
};

/*
 Function.prototype
*/
// 束縛 (7箇所で使用)
Function.prototype.curry = function () {
	var args = Array.from(arguments);
	var self = this;
	return function () {
		return self.apply(this, args.concat(Array.from(arguments)));
	};
};
Function.prototype.bindArgs = Function.prototype.curry;

// 遅延実行 (12箇所で使用)
Function.prototype.later = function(ms){
	var self = this;
	return function(){
		var args = arguments;
		var thisObject = this;
		var res = {
			complete: false,
			cancel: function(){clearTimeout(PID);},
			notify: function(){clearTimeout(PID);later_func()}
		};
		var later_func = function(){
			self.apply(thisObject,args);
			res.complete = true;
		};
		var PID = setTimeout(later_func,ms);
		return res;
	};
};
