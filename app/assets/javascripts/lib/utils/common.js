function arrayMode(arr){
	var hash = {};
	arr.forEach(function(v){
		hash[v] = hash[v] ? hash[v]+1 : 1;
	});
	var mode = Object.keys(hash).sort(function(a,b){
		return hash[b] - hash[a];
	});
	return mode[0];
}

function toRelativeDate(seconds){
	var k = seconds > 0 ? seconds : -seconds;
	var u = "sec";
	var jp = {
		sec : "秒",
		min : "分",
		hour: "時間",
		day : "日",
		Mon : "ヶ月"
	};
	var vec = seconds >= 0 ? "前" : "後";
	var st = 0;
	(k>=60) ? (k/=60,u="min",st=1) : 0;
	(st && k>=60) ? (k/=60,u="hour",st=1) : st=0;
	(st && k>=24) ? (k/=24,u="day" ,st=1) : st=0;
	(st && k>=30) ? (k/=30,u="Mon" ,st=1) : st=0;
	k = Math.floor(k);
	var v = jp[u];
	return (isNaN(k)) ? "nan" : k+v+vec;
}

function True(){return true}
function False(){return false}

function has_attr(id){
	return function(target){
		return this.getAttribute(id)
	}
}
function get_attr(id){
	return function(target){
		target = target || this;
		return target.getAttribute(id)
	}
}


var Util = {
	image:{},
	style:{}
};
Util.image.maxsize = function(w,h){
	var ow = this.width;
	var oh = this.height;
	var rw = ow;
	var rh = oh;
	if(ow > w){
		rw = w;
		rh = oh * (w / ow);
	}
	if(rh > h){
		rw = rw * (h / rh);
		rh = h;
	};
	this.width = rw;
	this.height = rh;
};
Util.style.visible = function(el){
	setStyle(el,{visibility:"visible"})
}
function swap_channel_image(el,src){
	el.onload = null;
	var img = new Image();
	var swap = function(){
		Util.image.maxsize.call(img,200,50);
		el.width  = img.width;
		el.height = img.height;
		el.src = src;
	};
	img.src = src;
	if(img.complete){
		swap()
	} else {
		img.onload = swap;
	}
}

function get_domain(url){
	var m = (url+'/').match(get_domain.reg);
	return m ? m[1] : "";
}
get_domain.reg = /https?:\/\/([^\/]*?)\//;


/*
 良く使う関数
*/

var GLOBAL = this;

// bench
function _$(el){
	//return typeof el == 'string' ? document.getElementById(el) : el;
	if(typeof el == 'string'){
		return (_$.cacheable[el])
			? _$.cache[el] || (_$.cache[el] = document.getElementById(el))
			: document.getElementById(el)
	} else {
		return el
	}
}

_$.cache = {};
_$.cacheable = {};



var _ = {};
$N = function (name, attr, childs) {
	var ret = document.createElement(name);
	for (var k in attr) {
		if (!attr.hasOwnProperty(k)) continue;
		var v = attr[k];
		(k == "class") ? (ret.className = v) :
		(k == "style") ? setStyle(ret,v) : ret.setAttribute(k, v);
	}
	var t = typeof clilds;
	(typeof childs === "string")? ret.appendChild(document.createTextNode(childs)) :
	(Array.isArray(childs)) ? childs.forEach(function(child){
		typeof child === "string"
			? ret.appendChild(document.createTextNode(child))
			: ret.appendChild(child);
		})
	: null;
	return ret;
};
function $DF(){
	var df = document.createDocumentFragment();
		Array.from(arguments).forEach(function(f){ df.appendChild(f) });
	return df;
}

function BrowserDetect(){
	var ua = navigator.userAgent;
	if(ua.indexOf( "KHTML" ) > -1) this.isKHTML = true;
	if(ua.indexOf( "Macintosh" ) > -1) this.isMac   = true;
	if(ua.indexOf( "Windows" ) > -1) this.isWin   = true;
	if(ua.indexOf( "Gecko" ) > -1 && !this.isKHTML) this.isGecko = true;
	if(ua.indexOf( "Firefox" ) > -1) this.isFirefox = true;
	this.isWindows = this.isWin;
	if(window.opera){
		this.isOpera = true;
	} else if(ua.indexOf( "MSIE" ) > -1){
		this.isIE = true;
	}
}




function clone(obj){
	return Object.assign({}, obj);
}
/* Perlのjoin、中の配列も含めて同じルールでjoinする  */
function join(){
	var args = Array.from(arguments);
	var sep = args.shift();
	var to_s = Array.prototype.toString;
	Array.prototype.toString = function(){return this.join(sep)}
	var res = args.join(sep);
	Array.prototype.toString = to_s;
	return res;
}

/*  */

function send(self,method,args){
	if(typeof self[method] === "function")
		return self[method].apply(self,args);
	else if(typeof self.method_missing === "function")
		return self.method_missing(method,args)
	else
		return null
}

function sender(method){
	var args = Array.from(arguments).slice(1);
	return function(self){
		var ex_args = Array.from(arguments);
		return send(self,method,args.concat(ex_args))
	}
}
/*
 push : function(item){ return this.list.push(item) }
 -> push : delegator("list","push");
*/
function delegator(key,method){
	return function(){
		var self = this[key];
		return self[method].apply(self,arguments);
	}
}

function getter(attr){
	return function(self){return self[attr]}
}

/*
 extend buildin object
*/
"String,Number,Array".split(",").forEach(function(c){
	var klass = GLOBAL[c];
	klass.extend = function(other){
		return Object.assign(klass.prototype, other);
	}
})
/*
  and more extra methods
*/

Array.extend({
	// 各要素にメソッドを送る
	invoke : function(){
		var args = Array.from(arguments);
		var method = args.shift();
		return this.map(sender(method,args));
	},
	// ハッシュの配列から指定キーのvalueのみを集めた配列を返す
	pluck : function(name){
		return this.map(getter(name))
	},
	partition : function(callback,thisObj) {
		var trues = [], falses = [];
		this.forEach(function(v,i,self){
			(callback.call(thisObj,v,i,self) ? trues : falses).push(v);
		});
		return [trues, falses];
	}
});

/* Accessor */
function Accessor(){
	var value;
	var p_getter = this.getter;
	var p_setter = this.setter;
	var accessor = function(new_value){
		if(arguments.length){
			var setter = accessor.setter || p_setter;
			return (value = setter(new_value, value));
		} else {
			var getter = accessor.getter || p_getter;
			return getter(value)
		}
		return (arguments.length) ? (value = new_value) : value
	};
	accessor.isAccessor = true;
	return accessor;
}
Accessor.prototype.getter = function(value){ return value };
Accessor.prototype.setter = function(value){ return value };

/*
 Cookie
*/
class Cookie {
	constructor(opt) {
		this._options = "name,value,expires,path,domain,secure".split(",");
		this._mk_accessors(this._options);
		this.expires.setter = function(value){
			if(value instanceof Date){
				value = this.expires.toString();
			} else if(typeof value === "number"){
				value = new Date(new Date() - 0 + value).toString();
			}
			return value
		}
		if(opt) this._set_options(opt);
	}
	_set_options(opt) {
		var self = this;
		this._options.forEach(function(key){
			opt.hasOwnProperty(key) && self[key](opt[key])
		})
	}
	_mk_accessors(args) {
		for(var i=0;i<args.length;i++){
			var name = args[i];
			this[name] = new Accessor()
		}
	}
	parse(str) {
		var hash = {};
		var ck = str || document.cookie;
		var pairs = ck.split(/\s*;\s*/);
		pairs.forEach(function(v){
			var tmp = v.split("=",2);
			hash[tmp[0]] = tmp[1];
		})
		return hash;
	}
	bake() {
		document.cookie = this.as_string();
	}
	as_string() {
		var e,p,d,s;
		e = this.expires();
		p = this.path();
		d = this.domain();
		s = this.secure();
		var options = [
			(e ? ";expires=" + e.toGMTString() : ""),
			(p ? ";path=" + p : ""),
			(d ? ";domain=" + d : ""),
			(s ? ";secure" : "")
		].join("");
		var cookie = [this.name(),"=",this.value(),options].join("");
		return cookie;
	}
}
Cookie.default_expire = 60*60*24*365*1000;
function setCookie(name,value,expires,path,domain,secure){
	if(expires instanceof Date){
		expire_str = "expires="+expires.toString();
	} else if(typeof expires === "number"){
		expire_str = "expires="+new Date(new Date() - 0 + expire).toString();
	} else {
		expire_str = "expires="+new Date(new Date() - 0 + Cookie.default_expire).toString();
	}
	if(!path) path = "; path=/;";
	var cookie = new Cookie({
		name    : name,
		value   : value,
		path    : path || "/",
		expires : expires
	});
	cookie.bake();
}
function getCookie(key){
	var hash = new Cookie().parse();
	return hash[key];
}


/* Number */
Number.extend({
	zerofill : function(len){
		var n = "" + this;
		for(;n.length < len;)
			n = "0" + n;
		return n;
	}
});

/*
 className
*/
function hasClass(element,classname){
	element = _$(element);
	return element.classList.contains(classname);
}
function addClass(element,classname){
	element = _$(element);
	element.classList.add(classname);
}
function removeClass(element,classname){
	element = _$(element);
	element.classList.remove(classname);
}
function switchClass(element, classname){
	element = _$(element);
	var ns = classname.split("-")[0] + "-";
	Array.from(element.classList).forEach(function(cls){
		if(cls.indexOf(ns) === 0) element.classList.remove(cls);
	});
	element.classList.add(classname);
}
function toggleClass(element, classname){
	element = _$(element);
	element.classList.toggle(classname);
}


/* Form */

var Form = {};
Form.toJson = function(form){
	var json = {};
	var len = form.elements.length;
	Array.from(form.elements).forEach(function(el){
		if(!el.name) return;
		var value = Form.getValue(el);
		if(value != null){
			json[el.name] = value
		}
	});
	return json;
};
Form.getValue = function(el){
	return (
		(/text|hidden|submit/.test(el.type)) ? el.value :
		(el.type == "checkbox" && el.checked) ? el.value :
		(el.type == "radio"    && el.checked) ? el.value :
		(el.tagName == "SELECT") ? el.options[el.selectedIndex].value :
		null
	)
};
// formを埋める
Form.fill = function(form,json){
	form = _$(form);
	Array.from(form.elements).forEach(function(el){
		var name = el.name;
		var value = json[name];
		if(!name || value == null) return;
		(/text|hidden|select|submit/.test(el.type)) ?
			(el.value = value) :
		(el.type == "checkbox") ? (el.value = value, el.checked = true) :
		(el.type == "radio") ?
			(value == el.value) ? (el.checked = true) : (el.checked = false) :
		null
	})
}
Form.setValue = function(el, value){
	el.value = value;

}

Object.assign(Form,{
	disable: function(el){
		_$(el).disabled = "disabled";
	},
	enable: function(el){
		_$(el).disabled = "";
	},
	disable_all: function(el){
		el = _$(el);
		Form.disable(el);
		var child = el.getElementsByTagName("*");
		Array.from(child).forEach(Form.disable);
	},
	enable_all: function(el){
		el = _$(el);
		Form.enable(el);
		var child = el.getElementsByTagName("*");
		Array.from(child).forEach(Form.enable);
	}
});


/* Cache */

class Cache {
	constructor(option) {
		this._index = {};
		this._exprs = {};
		this._cache = [];
		if(option){
			this.max = option.max || 0;
		}
	}
	_get(key) {
		return this._index["_" + key];
	}
	get(key) {
		return this._get(key)[1]
	}
	set(key,value) {
		// delete
		if(this.max && this._cache.length > this.max){
			var to_delete = this._cache.shift();
			delete this._index["_" + to_delete[0]];
		}
		// update
		if(this.has(key)){
			this._get(key)[1] = value;
		} else {
			// create
			var pair = [key,value];
			this._cache.push(pair);
			this._index["_"+key] = pair;
		}
		return value;
	}
	set_expr(key,expr) {
		this._exprs["_" + key] = expr;
	}
	get_expr(key) {
		return this._exprs["_" + key] || null;
	}
	check_expr(key) {
		var expr = this.get_expr(key);
		if(expr){
			var r = new Date() - expr;
			var f = (r < 0) ? true : false;
			// if(!f) message("再読み込みします")
			return f;
		} else {
			return true;
		}
	}
	has(key) {
		return (this._index.hasOwnProperty("_" + key) && this.check_expr(key));
	}
	clear() {
		this._index = {};
		this._cache  = [];
	}
	find_or_create(key,callback) {
		return this.has(key) ? this.get(key) : this.set(key,callback())
	}
}

Number.extend({
	times: function(callback){
		var c = 0;
		for(;c<this;c++) callback(c)
	}
});

String.escapeRules = [
	[/&/g , "&amp;"],
	[/</g , "&lt;"],
	[/>/g , "&gt;"]
];
String.unescapeRules = [
	[/&lt;/g,  "<"],
	[/&gt;/g,  ">"],
	[/&amp;/g, "&"]
];
String.extend({
	mreplace : function(rule){
		var tmp = ""+this;
		rule.forEach(function(v){
			tmp = tmp.replace(v[0],v[1])
		});
		return tmp;
	},
	escapeHTML : function(){ return this.mreplace(String.escapeRules) },
	unescapeHTML : function(){ return this.mreplace(String.unescapeRules) },
	ry : function(max,str){
		if(this.length <= max) return this;
		var tmp = this.split("");
		return [].concat(this.slice(0,max/2),str,this.slice(-max/2)).join("")
	},
	camelize : function(){ return this.replace(/-([a-z])/g, function(m, c){ return c.toUpperCase() }) }
});



Object.toQuery = function(self){
	var buf = [];
	for(var key in self){
		if(!self.hasOwnProperty(key)) continue;
		var value = self[key];
		if(typeof value === "function") continue;
		buf.push(
			encodeURIComponent(key)+"="+
			encodeURIComponent(value)
		)
	}
	return buf.join("&");
}


/* from prototype.js */

var Position = {
  // set to true if needed, warning: firefox performance problems
  // NOT neeeded for page scrolling, only if draggable contained in
  // scrollable elements
  includeScrollOffsets: false,

  // must be called before calling withinIncludingScrolloffset, every time the
  // page is scrolled
  prepare: function() {
    this.deltaX =  window.pageXOffset
                || document.documentElement.scrollLeft
                || document.body.scrollLeft
                || 0;
    this.deltaY =  window.pageYOffset
                || document.documentElement.scrollTop
                || document.body.scrollTop
                || 0;
  },

  realOffset: function(element) {
    var valueT = 0, valueL = 0;
    do {
      valueT += element.scrollTop  || 0;
      valueL += element.scrollLeft || 0;
      element = element.parentNode;
    } while (element);
    return [valueL, valueT];
  },

  cumulativeOffset: function(element) {
    var valueT = 0, valueL = 0;
    do {
      valueT += element.offsetTop  || 0;
      valueL += element.offsetLeft || 0;
      element = element.offsetParent;
    } while (element);
    return [valueL, valueT];
  },

  positionedOffset: function(element) {
    var valueT = 0, valueL = 0;
    do {
      valueT += element.offsetTop  || 0;
      valueL += element.offsetLeft || 0;
      element = element.offsetParent;
      if (element) {
        p = Element.getStyle(element, 'position');
        if (p == 'relative' || p == 'absolute') break;
      }
    } while (element);
    return [valueL, valueT];
  },

  offsetParent: function(element) {
    if (element.offsetParent) return element.offsetParent;
    if (element == document.body) return element;

    while ((element = element.parentNode) && element != document.body)
      if (Element.getStyle(element, 'position') != 'static')
        return element;

    return document.body;
  },

  // caches x/y coordinate pair to use with overlap
  within: function(element, x, y) {
    if (this.includeScrollOffsets)
      return this.withinIncludingScrolloffsets(element, x, y);
    this.xcomp = x;
    this.ycomp = y;
    this.offset = this.cumulativeOffset(element);

    return (y >= this.offset[1] &&
            y <  this.offset[1] + element.offsetHeight &&
            x >= this.offset[0] &&
            x <  this.offset[0] + element.offsetWidth);
  },

  withinIncludingScrolloffsets: function(element, x, y) {
    var offsetcache = this.realOffset(element);

    this.xcomp = x + offsetcache[0] - this.deltaX;
    this.ycomp = y + offsetcache[1] - this.deltaY;
    this.offset = this.cumulativeOffset(element);

    return (this.ycomp >= this.offset[1] &&
            this.ycomp <  this.offset[1] + element.offsetHeight &&
            this.xcomp >= this.offset[0] &&
            this.xcomp <  this.offset[0] + element.offsetWidth);
  },

  // within must be called directly before
  overlap: function(mode, element) {
    if (!mode) return 0;
    if (mode == 'vertical')
      return ((this.offset[1] + element.offsetHeight) - this.ycomp) /
        element.offsetHeight;
    if (mode == 'horizontal')
      return ((this.offset[0] + element.offsetWidth) - this.xcomp) /
        element.offsetWidth;
  },

  clone: function(source, target) {
    source = _$(source);
    target = _$(target);
    target.style.position = 'absolute';
    var offsets = this.cumulativeOffset(source);
    target.style.top    = offsets[1] + 'px';
    target.style.left   = offsets[0] + 'px';
    target.style.width  = source.offsetWidth + 'px';
    target.style.height = source.offsetHeight + 'px';
  },

  page: function(forElement) {
    var valueT = 0, valueL = 0;

    var element = forElement;
    do {
      valueT += element.offsetTop  || 0;
      valueL += element.offsetLeft || 0;

      // Safari fix
      if (element.offsetParent==document.body)
        if (Element.getStyle(element,'position')=='absolute') break;

    } while (element = element.offsetParent);

    element = forElement;
    do {
      valueT -= element.scrollTop  || 0;
      valueL -= element.scrollLeft || 0;
    } while (element = element.parentNode);

    return [valueL, valueT];
  },

  clone: function(source, target) {
    var options = Object.assign({
      setLeft:    true,
      setTop:     true,
      setWidth:   true,
      setHeight:  true,
      offsetTop:  0,
      offsetLeft: 0
    }, arguments[2] || {})

    // find page position of source
    source = _$(source);
    var p = Position.page(source);

    // find coordinate system to use
    target = _$(target);
    var delta = [0, 0];
    var parent = null;
    // delta [0,0] will do fine with position: fixed elements,
    // position:absolute needs offsetParent deltas
    if (Element.getStyle(target,'position') == 'absolute') {
      parent = Position.offsetParent(target);
      delta = Position.page(parent);
    }

    // correct by body offsets (fixes Safari)
    if (parent == document.body) {
      delta[0] -= document.body.offsetLeft;
      delta[1] -= document.body.offsetTop;
    }

    // set position
    if(options.setLeft)   target.style.left  = (p[0] - delta[0] + options.offsetLeft) + 'px';
    if(options.setTop)    target.style.top   = (p[1] - delta[1] + options.offsetTop) + 'px';
    if(options.setWidth)  target.style.width = source.offsetWidth + 'px';
    if(options.setHeight) target.style.height = source.offsetHeight + 'px';
  },

  absolutize: function(element) {
    element = _$(element);
    if (element.style.position == 'absolute') return;
    Position.prepare();

    var offsets = Position.positionedOffset(element);
    var top     = offsets[1];
    var left    = offsets[0];
    var width   = element.clientWidth;
    var height  = element.clientHeight;

    element._originalLeft   = left - parseFloat(element.style.left  || 0);
    element._originalTop    = top  - parseFloat(element.style.top || 0);
    element._originalWidth  = element.style.width;
    element._originalHeight = element.style.height;

    element.style.position = 'absolute';
    element.style.top    = top + 'px';;
    element.style.left   = left + 'px';;
    element.style.width  = width + 'px';;
    element.style.height = height + 'px';;
  },

  relativize: function(element) {
    element = _$(element);
    if (element.style.position == 'relative') return;
    Position.prepare();

    element.style.position = 'relative';
    var top  = parseFloat(element.style.top  || 0) - (element._originalTop || 0);
    var left = parseFloat(element.style.left || 0) - (element._originalLeft || 0);

    element.style.top    = top + 'px';
    element.style.left   = left + 'px';
    element.style.height = element._originalHeight;
    element.style.width  = element._originalWidth;
  }
}

// Safari returns margins on body which is incorrect if the child is absolutely
// positioned.  For performance reasons, redefine Position.cumulativeOffset for
// KHTML/WebKit only.
if (/Konqueror|Safari|KHTML/.test(navigator.userAgent)) {
  Position.cumulativeOffset = function(element) {
    var valueT = 0, valueL = 0;
    do {
      valueT += element.offsetTop  || 0;
      valueL += element.offsetLeft || 0;
      if (element.offsetParent == document.body)
        if (Element.getStyle(element, 'position') == 'absolute') break;

      element = element.offsetParent;
    } while (element);

    return [valueL, valueT];
  }
}

Position.cumulativeOffsetFrom = function(element,from) {
    var valueT = 0, valueL = 0;
    do {
      valueT += element.offsetTop  || 0;
      valueL += element.offsetLeft || 0;
      element = element.offsetParent;
    } while (element && element != from);
    return [valueL, valueT];
};


/* CSS */
function parseCSS(text){
	var pairs = text.split(";");
	var res = {};
	pairs.forEach(function(pair){
		var tmp = pair.split(":");
		res[tmp[0].trim()] = tmp[1];
	});
	return res;
}
// cssセット、透明度、floatの互換性を取る
function setStyle(element,style){
	element = _$(element);
	var es = element.style;
	if(typeof style === "string"){
		es.cssText ? (es.cssText = style) : setStyle(element,parseCSS(style));
	} else {
		// objectの場合
		Object.entries(style).forEach(function(entry){
			var key = entry[0], value = entry[1];
			if(setStyle.hack.hasOwnProperty(key)){
				var tmp = setStyle.hack[key](key,value);
				key = tmp[0],value = tmp[1]
			}
			element.style[key.camelize()] = value
		});
	}
}
setStyle.hack = {
	opacity : function(key,value){
		return [ key , value]
	}
}

function getStyle(o,s){
	var res;
	try{
		res = getComputedStyle(o, null).getPropertyValue(s);
		return res;
	} catch(e){}
	return "";
}

/*
*/

// var Config = {}
// Task
/*
 並列してリクエストを投げる、
  - 完了したものからcompleteフラグを立てる
  - 監視者のupdateメソッドを呼び出す

 var task = new Task([loadConfig,func,func]);
 task.oncomplete = function(){
 	// complete !
 };
 task.exec();

 api["config/load"] = new LDR.API("/api/config/load").requester("post");
 new Task(loadconfig);
 LDR.API.prototype.toTask = function(){

 }
*/



/*
 invoke 別のクラスに処理を伝播させる
  invoke(this, "method_name", arguments);
*/
function invoke(obj, method, args){
	var o = obj.parent;
	for (;typeof(o) != 'undefined'; o = o.parent) {
		if (typeof(o[method]) == 'function') {
			return o[method].apply(obj, args);
		}
	}
	return false;
}

Function.prototype.forEachArgs = function(callback){
	var f = this;
	return function(){
		var target = Array.from(arguments).flat(Infinity);
		if(!target.length) return;
		target.forEach(function(v){
			callback ? f(callback(v)) : f(v)
		})
	}
};

// last_error
window.__ERROR__ = null;
Function.prototype._try = function(){
	var self = this;
	return function(){
		try{
			return self.apply(this, arguments)
		} catch(e){
			__ERROR__ = e;
			// alert(e);
		}
	}
};

/*
 Element Updater
*/
function MakeUpdater(label){
	var hash = {};
	var updater = (label?label+"_":"") + "updater";
	var update  = (label?label+"_":"") + "update";
	function get_func(label){
		return(
			typeof hash["_"+label] === "function"
			 ? hash["_" + label]
			 : function(){}
		);
	}
	var u = GLOBAL[update] = function(label){
		if(label instanceof RegExp){
			Object.keys(hash).filter(function(l){
				l = l.slice(1);
				return label.test(l)
			}).forEach(function(label){
				label = label.slice(1);
				get_func(label).call(_$(label));
			})
		} else {
			return get_func(label).call(_$(label));
		}
	}.forEachArgs();
	GLOBAL[updater] = function(label, callback){
		if(callback){
			hash["_"+label] = callback;
		} else {
			return function(){ u(label) }
		}
	};
}
MakeUpdater();

var Element = {
	show: function(el){
		if(el) el.style.display = "block"
	}.forEachArgs(_$),
	hide: function(el){
		if(el) el.style.display = "none"
	}.forEachArgs(_$),
	toggle: function(el){
		el = _$(el);
		el.style.display = (el.style.display != "block") ? "block" : "none";
	},
	childOf: function(){},
	getStyle : getStyle
};

GLOBAL.sortModes = {
      modified_on: "New",
      "modified_on:reverse": "Old",
      unread_count: "Unread Items (desc.)",
      "unread_count:reverse": "Unread items (asc.)",
      "title:reverse": "Title",
      rate: "Rating",
      subscribers_count: "Subscribers (desc.)",
      "subscribers_count:reverse": "Subscribers (asc.)"
    }

GLOBAL.viewModes = {
          flat: "Flat",
          folder: "Folder",
          rate: "Rating",
          subscribers: "Subscribers",
          domain: "Domain",
    }
