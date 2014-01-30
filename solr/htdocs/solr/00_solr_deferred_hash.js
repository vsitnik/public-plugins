// Generated by CoffeeScript 1.5.0
(function() {

  window.DeferredHash = (function() {

    function DeferredHash(that, complete) {
      this.that = that;
      this.complete = complete;
      this.data = {};
      this.outstanding = {};
      this.num = 0;
      this._go = 0;
    }

    DeferredHash.prototype.add = function(key) {
      this.outstanding[key] = 1;
      return this.num++;
    };

    DeferredHash.prototype.done = function(key, data) {
      this.data[key] = data;
      delete this.outstanding[key];
      this.num--;
      if (this.num === 0 && this._go) {
        return this.complete.call(this.that, this.data);
      }
    };

    DeferredHash.prototype.go = function() {
      this._go = 1;
      if (this.num === 0) {
        return this.complete.call(this.that, this.data);
      }
    };

    return DeferredHash;

  })();

}).call(this);
