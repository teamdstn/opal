class String
  include Comparable

  `def._isString = true`

  def self.try_convert(what)
    what.to_str
  rescue
    nil
  end

  def self.new(str = '')
    `new String(str)`
  end

  def %(data)
    if Array === data
      format(self, *data)
    else
      format(self, data)
    end
  end

  def *(count)
    %x{
      if (count < 1) {
        return '';
      }

      var result  = '',
          pattern = self;

      while (count > 0) {
        if (count & 1) {
          result += pattern;
        }

        count >>= 1;
        pattern += pattern;
      }

      return result;
    }
  end

  def +(other)
    other = Opal.coerce_to other, String, :to_str

    `self + #{other.to_s}`
  end

  def <=>(other)
    if other.respond_to? :to_str
      other = other.to_str.to_s

      `self > other ? 1 : (self < other ? -1 : 0)`
    else
      %x{
        var cmp = #{other <=> self};

        if (cmp === nil) {
          return nil;
        }
        else {
          return cmp > 0 ? -1 : (cmp < 0 ? 1 : 0);
        }
      }
    end
  end

  def ==(other)
    `!!(other._isString && self.valueOf() === other.valueOf())`
  end

  alias === ==

  def =~(other)
    %x{
      if (other._isString) {
        #{raise TypeError, 'type mismatch: String given'};
      }

      return #{other =~ self};
    }
  end

  def [](index, length = undefined)
    %x{
      var size = self.length;

      if (index._isRange) {
        var exclude = index.exclude,
            length  = index.end,
            index   = index.begin;

        if (index < 0) {
          index += size;
        }

        if (length < 0) {
          length += size;
        }

        if (!exclude) {
          length += 1;
        }

        if (index > size) {
          return nil;
        }

        length = length - index;

        if (length < 0) {
          length = 0;
        }

        return self.substr(index, length);
      }

      if (index < 0) {
        index += self.length;
      }

      if (length == null) {
        if (index >= self.length || index < 0) {
          return nil;
        }

        return self.substr(index, 1);
      }

      if (index > self.length || index < 0) {
        return nil;
      }

      return self.substr(index, length);
    }
  end

  def capitalize
    `self.charAt(0).toUpperCase() + self.substr(1).toLowerCase()`
  end

  def casecmp(other)
    other = Opal.coerce_to(other, String, :to_str).to_s

    `self.toLowerCase()` <=> `other.toLowerCase()`
  end

  def center(width, padstr = ' ')
    width  = Opal.coerce_to(width, Integer, :to_int)
    padstr = Opal.coerce_to(padstr, String, :to_str).to_s

    if padstr.empty?
      raise ArgumentError, 'zero width padding'
    end

    return self if `width <= self.length`

    %x{
      var ljustified = #{ljust ((width + @length) / 2).ceil, padstr},
          rjustified = #{rjust ((width + @length) / 2).floor, padstr};

      return rjustified + ljustified.slice(self.length);
    }
  end

  def chars(&block)
    return each_char.to_a unless block

    each_char(&block)
  end

  def chomp(separator = $/)
    return self if `separator === nil || self.length === 0`

    separator = Opal.coerce_to!(separator, String, :to_str).to_s

    %x{
      if (separator === "\\n") {
        return self.replace(/\\r?\\n?$/, '');
      }
      else if (separator === "") {
        return self.replace(/(\\r?\\n)+$/, '');
      }
      else if (self.length > separator.length) {
        var tail = self.substr(-1 * separator.length);

        if (tail === separator) {
          return self.substr(0, self.length - separator.length);
        }
      }
    }

    self
  end

  def chop
    %x{
      var length = self.length;

      if (length <= 1) {
        return "";
      }

      if (self.charAt(length - 1) === "\\n" && self.charAt(length - 2) === "\\r") {
        return self.substr(0, length - 2);
      }
      else {
        return self.substr(0, length - 1);
      }
    }
  end

  def chr
    `self.charAt(0)`
  end

  def clone
    copy = `self.slice()`
    copy.initialize_clone(self)
    copy
  end

  def dup
    copy = `self.slice()`
    copy.initialize_dup(self)
    copy
  end

  def count(str)
    `(self.length - self.replace(new RegExp(str, 'g'), '').length) / str.length`
  end

  alias dup clone

  def downcase
    `self.toLowerCase()`
  end

  def each_char(&block)
    return enum_for :each_char unless block_given?

    %x{
      for (var i = 0, length = self.length; i < length; i++) {
        #{yield `self.charAt(i)`};
      }
    }

    self
  end

  def each_line(separator = $/)
    return split(separator) unless block_given?

    %x{
      var chomped  = #{chomp},
          trailing = self.length != chomped.length,
          splitted = chomped.split(separator);

      for (var i = 0, length = splitted.length; i < length; i++) {
        if (i < length - 1 || trailing) {
          #{yield `splitted[i] + separator`};
        }
        else {
          #{yield `splitted[i]`};
        }
      }
    }

    self
  end

  def empty?
    `self.length === 0`
  end

  def end_with?(*suffixes)
    %x{
      for (var i = 0, length = suffixes.length; i < length; i++) {
        var suffix = #{Opal.coerce_to `suffixes[i]`, String, :to_str};

        if (self.length >= suffix.length && self.substr(0 - suffix.length) === suffix) {
          return true;
        }
      }
    }

    false
  end

  alias eql? ==
  alias equal? ===

  def gsub(pattern, replace = undefined, &block)
    if String === pattern || pattern.respond_to?(:to_str)
      pattern = /#{Regexp.escape(pattern.to_str)}/
    end

    unless Regexp === pattern
      raise TypeError, "wrong argument type #{pattern.class} (expected Regexp)"
    end

    %x{
      var pattern = pattern.toString(),
          options = pattern.substr(pattern.lastIndexOf('/') + 1) + 'g',
          regexp  = pattern.substr(1, pattern.lastIndexOf('/') - 1);

      #{self}.$sub._p = block;
      return #{self}.$sub(new RegExp(regexp, options), replace);
    }
  end

  def hash
    `#{self}.toString()`
  end

  def hex
    to_i 16
  end

  def include?(other)
    %x{
      if (other._isString) {
        return self.indexOf(other) !== -1;
      }
    }

    unless other.respond_to? :to_str
      raise TypeError, "no implicit conversion of #{other.class.name} into String"
    end

    `self.indexOf(#{other.to_str}) !== -1`
  end

  def index(what, offset = nil)
    if String === what
      what = what.to_s
    elsif what.respond_to? :to_str
      what = what.to_str.to_s
    elsif not Regexp === what
      raise TypeError, "type mismatch: #{what.class} given"
    end

    result = -1

    if offset
      offset = Opal.coerce_to offset, Integer, :to_int

      %x{
        var size = self.length;

        if (offset < 0) {
          offset = offset + size;
        }

        if (offset > size) {
          return nil;
        }
      }

      if Regexp === what
        result = (what =~ `self.substr(offset)`) || -1
      else
        result = `self.substr(offset).indexOf(what)`
      end

      %x{
        if (result !== -1) {
          result += offset;
        }
      }
    else
      if Regexp === what
        result = (what =~ self) || -1
      else
        result = `self.indexOf(what)`
      end
    end

    unless `result === -1`
      result
    end
  end

  def inspect
    %x{
      var escapable = /[\\\\\\"\\x00-\\x1f\\x7f-\\x9f\\u00ad\\u0600-\\u0604\\u070f\\u17b4\\u17b5\\u200c-\\u200f\\u2028-\\u202f\\u2060-\\u206f\\ufeff\\ufff0-\\uffff]/g,
          meta      = {
            '\\b': '\\\\b',
            '\\t': '\\\\t',
            '\\n': '\\\\n',
            '\\f': '\\\\f',
            '\\r': '\\\\r',
            '"' : '\\\\"',
            '\\\\': '\\\\\\\\'
          };

      escapable.lastIndex = 0;

      return escapable.test(self) ? '"' + self.replace(escapable, function(a) {
        var c = meta[a];

        return typeof c === 'string' ? c :
          '\\\\u' + ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
      }) + '"' : '"' + self + '"';
    }
  end

  def intern
    self
  end

  def lines(separator = $/)
    each_line(separator).to_a
  end

  def length
    `self.length`
  end

  def ljust(width, padstr = ' ')
    width  = Opal.coerce_to(width, Integer, :to_int)
    padstr = Opal.coerce_to(padstr, String, :to_str).to_s

    if padstr.empty?
      raise ArgumentError, 'zero width padding'
    end

    return self if `width <= self.length`

    %x{
      var index  = -1,
          result = "";

      width -= self.length;

      while (++index < width) {
        result += padstr;
      }

      return self + result.slice(0, width);
    }
  end

  def lstrip
    `self.replace(/^\\s*/, '')`
  end

  def match(pattern, pos = undefined, &block)
    if String === pattern || pattern.respond_to?(:to_str)
      pattern = /#{Regexp.escape(pattern.to_str)}/
    end

    unless Regexp === pattern
      raise TypeError, "wrong argument type #{pattern.class} (expected Regexp)"
    end

    pattern.match(self, pos, &block)
  end

  def next
    %x{
      if (#{self}.length === 0) {
        return "";
      }

      var initial = #{self}.substr(0, #{self}.length - 1);
      var last    = String.fromCharCode(#{self}.charCodeAt(#{self}.length - 1) + 1);

      return initial + last;
    }
  end

  def ord
    `#{self}.charCodeAt(0)`
  end

  def partition(str)
    %x{
      var result = #{self}.split(str);
      var splitter = (result[0].length === #{self}.length ? "" : str);

      return [result[0], splitter, result.slice(1).join(str.toString())];
    }
  end

  def reverse
    `#{self}.split('').reverse().join('')`
  end

  # TODO handle case where search is regexp
  def rindex(search, offset = undefined)
    %x{
      var search_type = (search == null ? Opal.NilClass : search.constructor);
      if (search_type != String && search_type != RegExp) {
        var msg = "type mismatch: " + search_type + " given";
        #{raise TypeError.new(`msg`)};
      }

      if (#{self}.length == 0) {
        return search.length == 0 ? 0 : nil;
      }

      var result = -1;
      if (offset != null) {
        if (offset < 0) {
          offset = #{self}.length + offset;
        }

        if (search_type == String) {
          result = #{self}.lastIndexOf(search, offset);
        }
        else {
          result = #{self}.substr(0, offset + 1).$reverse().search(search);
          if (result !== -1) {
            result = offset - result;
          }
        }
      }
      else {
        if (search_type == String) {
          result = #{self}.lastIndexOf(search);
        }
        else {
          result = #{self}.$reverse().search(search);
          if (result !== -1) {
            result = #{self}.length - 1 - result;
          }
        }
      }

      return result === -1 ? nil : result;
    }
  end

  def rjust(width, padstr = ' ')
    width  = Opal.coerce_to(width, Integer, :to_int)
    padstr = Opal.coerce_to(padstr, String, :to_str).to_s

    if padstr.empty?
      raise ArgumentError, 'zero width padding'
    end

    return self if `width <= self.length`

    %x{
      var chars     = Math.floor(width - self.length),
          patterns  = Math.floor(chars / padstr.length),
          result    = Array(patterns + 1).join(padstr),
          remaining = chars - result.length;

      return result + padstr.slice(0, remaining) + self;
    }
  end

  def rstrip
    `self.replace(/\\s*$/, '')`
  end

  def scan(pattern, &block)
    %x{
      if (pattern.global) {
        // should we clear it afterwards too?
        pattern.lastIndex = 0;
      }
      else {
        // rewrite regular expression to add the global flag to capture pre/post match
        pattern = new RegExp(pattern.source, 'g' + (pattern.multiline ? 'm' : '') + (pattern.ignoreCase ? 'i' : ''));
      }

      var result = [];
      var match;

      while ((match = pattern.exec(#{self})) != null) {
        var match_data = #{MatchData.new `pattern`, `match`};
        if (block === nil) {
          match.length == 1 ? result.push(match[0]) : result.push(match.slice(1));
        }
        else {
          match.length == 1 ? block(match[0]) : block.apply(#{self}, match.slice(1));
        }
      }

      return (block !== nil ? #{self} : result);
    }
  end

  alias size length

  alias slice []

  def split(pattern = $; || ' ', limit = undefined)
    %x{
      if (pattern && pattern._isRegexp) {
          return #{self}.split(pattern, limit);
        } else {
          result = [],
          splitted = start = lim = 0,
          splat = #{Opal.try_convert(pattern, String, :to_str).to_s};

          if (undefined !== limit) {
            lim = #{Opal.try_convert(limit, Integer, :to_int)};
          }

          if (pattern === nil) {
            if (#{$;} === undefined || #{$;} === nil) {
              splat = ' ';
            }
            else {
              splat = #{$;};
            }
          }

          if (lim == 1) {
            if (#{self}.length == 0) {
              return [];
            }
            else {
              return [#{self}];
            }
          }

          while ((cursor = #{self}.indexOf(splat, start)) > -1 && cursor < #{self}.length) {
            if (splitted + 1 == lim) {
              break;
            }

            if (splat == ' ' && cursor == start) {
              start = cursor + 1;
              continue;
            }

            result.push(#{self}.substr(start, splat.length ? cursor - start : 1));
            splitted++;

            start = cursor + (splat.length ? splat.length : 1);
          }

          if (#{self}.length > 0 && (limit || lim < 0 || #{self}.length > start)) {
            if (#{self}.length == start) {
              result.push('');
            }
            else {
              result.push(#{self}.substr(start, #{self}.length));
            }
          }

          if (limit === undefined || lim == 0) {
            while (result.length > 0 && result[result.length - 1].length == 0) {
              result.pop();
            }
          }

          return result;
        }
    }
  end

  def start_with?(*prefixes)
    %x{
      for (var i = 0, length = prefixes.length; i < length; i++) {
        var prefix = #{Opal.coerce_to `prefixes[i]`, String, :to_str};

        if (self.indexOf(prefix) === 0) {
          return true;
        }
      }

      return false;
    }
  end

  def strip
    `#{self}.replace(/^\\s*/, '').replace(/\\s*$/, '')`
  end

  def sub(pattern, replace = undefined, &block)
    %x{
      if (typeof(replace) === 'string') {
        // convert Ruby back reference to JavaScript back reference
        replace = replace.replace(/\\\\([1-9])/g, '$$$1')
        return #{self}.replace(pattern, replace);
      }
      if (block !== nil) {
        return #{self}.replace(pattern, function() {
          // FIXME: this should be a formal MatchData object with all the goodies
          var match_data = []
          for (var i = 0, len = arguments.length; i < len; i++) {
            var arg = arguments[i];
            if (arg == undefined) {
              match_data.push(nil);
            }
            else {
              match_data.push(arg);
            }
          }

          var str = match_data.pop();
          var offset = match_data.pop();
          var match_len = match_data.length;

          // $1, $2, $3 not being parsed correctly in Ruby code
          //for (var i = 1; i < match_len; i++) {
          //  __gvars[String(i)] = match_data[i];
          //}
          #{$& = `match_data[0]`};
          #{$~ = `match_data`};
          return block(match_data[0]);
        });
      }
      else if (replace !== undefined) {
        if (#{replace.is_a?(Hash)}) {
          return #{self}.replace(pattern, function(str) {
            var value = #{replace[str]};

            return (value == null) ? nil : #{value.to_s};
          });
        }
        else {
          replace = #{String.try_convert(replace)};

          if (replace == null) {
            #{raise TypeError, "can't convert #{replace.class} into String"};
          }

          return #{self}.replace(pattern, replace);
        }
      }
      else {
        // convert Ruby back reference to JavaScript back reference
        replace = replace.toString().replace(/\\\\([1-9])/g, '$$$1')
        return #{self}.replace(pattern, replace);
      }
    }
  end

  alias succ next

  def sum(n = 16)
    %x{
      var result = 0;

      for (var i = 0, length = #{self}.length; i < length; i++) {
        result += (#{self}.charCodeAt(i) % ((1 << n) - 1));
      }

      return result;
    }
  end

  def swapcase
    %x{
      var str = #{self}.replace(/([a-z]+)|([A-Z]+)/g, function($0,$1,$2) {
        return $1 ? $0.toUpperCase() : $0.toLowerCase();
      });

      if (#{self}.constructor === String) {
        return str;
      }

      return #{self.class.new `str`};
    }
  end

  def to_a
    %x{
      if (#{self}.length === 0) {
        return [];
      }

      return [#{self}];
    }
  end

  def to_f
    %x{
      if (self.charAt(0) === '_') {
        return 0;
      }

      var result = parseFloat(self.replace(/_/g, ''));

      if (isNaN(result) || result == Infinity || result == -Infinity) {
        return 0;
      }
      else {
        return result;
      }
    }
  end

  def to_i(base = 10)
    %x{
      var result = parseInt(#{self}, base);

      if (isNaN(result)) {
        return 0;
      }

      return result;
    }
  end

  def to_proc
    %x{
      var name = '$' + #{self};

      return function(arg) {
        var meth = arg[name];
        return meth ? meth.call(arg) : arg.$method_missing(name);
      };
    }
  end

  def to_s
    `#{self}.toString()`
  end

  alias to_str to_s

  alias to_sym intern

  def tr(from, to)
    %x{
      if (from.length == 0 || from === to) {
        return #{self};
      }

      var subs = {};
      var from_chars = from.split('');
      var from_length = from_chars.length;
      var to_chars = to.split('');
      var to_length = to_chars.length;

      var inverse = false;
      var global_sub = null;
      if (from_chars[0] === '^') {
        inverse = true;
        from_chars.shift();
        global_sub = to_chars[to_length - 1]
        from_length -= 1;
      }

      var from_chars_expanded = [];
      var last_from = null;
      var in_range = false;
      for (var i = 0; i < from_length; i++) {
        var char = from_chars[i];
        if (last_from == null) {
          last_from = char;
          from_chars_expanded.push(char);
        }
        else if (char === '-') {
          if (last_from === '-') {
            from_chars_expanded.push('-');
            from_chars_expanded.push('-');
          }
          else if (i == from_length - 1) {
            from_chars_expanded.push('-');
          }
          else {
            in_range = true;
          }
        }
        else if (in_range) {
          var start = last_from.charCodeAt(0) + 1;
          var end = char.charCodeAt(0);
          for (var c = start; c < end; c++) {
            from_chars_expanded.push(String.fromCharCode(c));
          }
          from_chars_expanded.push(char);
          in_range = null;
          last_from = null;
        }
        else {
          from_chars_expanded.push(char);
        }
      }

      from_chars = from_chars_expanded;
      from_length = from_chars.length;

      if (inverse) {
        for (var i = 0; i < from_length; i++) {
          subs[from_chars[i]] = true;
        }
      }
      else {
        if (to_length > 0) {
          var to_chars_expanded = [];
          var last_to = null;
          var in_range = false;
          for (var i = 0; i < to_length; i++) {
            var char = to_chars[i];
            if (last_from == null) {
              last_from = char;
              to_chars_expanded.push(char);
            }
            else if (char === '-') {
              if (last_to === '-') {
                to_chars_expanded.push('-');
                to_chars_expanded.push('-');
              }
              else if (i == to_length - 1) {
                to_chars_expanded.push('-');
              }
              else {
                in_range = true;
              }
            }
            else if (in_range) {
              var start = last_from.charCodeAt(0) + 1;
              var end = char.charCodeAt(0);
              for (var c = start; c < end; c++) {
                to_chars_expanded.push(String.fromCharCode(c));
              }
              to_chars_expanded.push(char);
              in_range = null;
              last_from = null;
            }
            else {
              to_chars_expanded.push(char);
            }
          }

          to_chars = to_chars_expanded;
          to_length = to_chars.length;
        }

        var length_diff = from_length - to_length;
        if (length_diff > 0) {
          var pad_char = (to_length > 0 ? to_chars[to_length - 1] : '');
          for (var i = 0; i < length_diff; i++) {
            to_chars.push(pad_char);
          }
        }

        for (var i = 0; i < from_length; i++) {
          subs[from_chars[i]] = to_chars[i];
        }
      }

      var new_str = ''
      for (var i = 0, length = #{self}.length; i < length; i++) {
        var char = #{self}.charAt(i);
        var sub = subs[char];
        if (inverse) {
          new_str += (sub == null ? global_sub : char);
        }
        else {
          new_str += (sub != null ? sub : char);
        }
      }
      return new_str;
    }
  end

  def tr_s(from, to)
    %x{
      if (from.length == 0) {
        return #{self};
      }

      var subs = {};
      var from_chars = from.split('');
      var from_length = from_chars.length;
      var to_chars = to.split('');
      var to_length = to_chars.length;

      var inverse = false;
      var global_sub = null;
      if (from_chars[0] === '^') {
        inverse = true;
        from_chars.shift();
        global_sub = to_chars[to_length - 1]
        from_length -= 1;
      }

      var from_chars_expanded = [];
      var last_from = null;
      var in_range = false;
      for (var i = 0; i < from_length; i++) {
        var char = from_chars[i];
        if (last_from == null) {
          last_from = char;
          from_chars_expanded.push(char);
        }
        else if (char === '-') {
          if (last_from === '-') {
            from_chars_expanded.push('-');
            from_chars_expanded.push('-');
          }
          else if (i == from_length - 1) {
            from_chars_expanded.push('-');
          }
          else {
            in_range = true;
          }
        }
        else if (in_range) {
          var start = last_from.charCodeAt(0) + 1;
          var end = char.charCodeAt(0);
          for (var c = start; c < end; c++) {
            from_chars_expanded.push(String.fromCharCode(c));
          }
          from_chars_expanded.push(char);
          in_range = null;
          last_from = null;
        }
        else {
          from_chars_expanded.push(char);
        }
      }

      from_chars = from_chars_expanded;
      from_length = from_chars.length;

      if (inverse) {
        for (var i = 0; i < from_length; i++) {
          subs[from_chars[i]] = true;
        }
      }
      else {
        if (to_length > 0) {
          var to_chars_expanded = [];
          var last_to = null;
          var in_range = false;
          for (var i = 0; i < to_length; i++) {
            var char = to_chars[i];
            if (last_from == null) {
              last_from = char;
              to_chars_expanded.push(char);
            }
            else if (char === '-') {
              if (last_to === '-') {
                to_chars_expanded.push('-');
                to_chars_expanded.push('-');
              }
              else if (i == to_length - 1) {
                to_chars_expanded.push('-');
              }
              else {
                in_range = true;
              }
            }
            else if (in_range) {
              var start = last_from.charCodeAt(0) + 1;
              var end = char.charCodeAt(0);
              for (var c = start; c < end; c++) {
                to_chars_expanded.push(String.fromCharCode(c));
              }
              to_chars_expanded.push(char);
              in_range = null;
              last_from = null;
            }
            else {
              to_chars_expanded.push(char);
            }
          }

          to_chars = to_chars_expanded;
          to_length = to_chars.length;
        }

        var length_diff = from_length - to_length;
        if (length_diff > 0) {
          var pad_char = (to_length > 0 ? to_chars[to_length - 1] : '');
          for (var i = 0; i < length_diff; i++) {
            to_chars.push(pad_char);
          }
        }

        for (var i = 0; i < from_length; i++) {
          subs[from_chars[i]] = to_chars[i];
        }
      }
      var new_str = ''
      var last_substitute = null
      for (var i = 0, length = #{self}.length; i < length; i++) {
        var char = #{self}.charAt(i);
        var sub = subs[char]
        if (inverse) {
          if (sub == null) {
            if (last_substitute == null) {
              new_str += global_sub;
              last_substitute = true;
            }
          }
          else {
            new_str += char;
            last_substitute = null;
          }
        }
        else {
          if (sub != null) {
            if (last_substitute == null || last_substitute !== sub) {
              new_str += sub;
              last_substitute = sub;
            }
          }
          else {
            new_str += char;
            last_substitute = null;
          }
        }
      }
      return new_str;
    }
  end

  def upcase
    `self.toUpperCase()`
  end

  def freeze
    self
  end

  def frozen?
    true
  end
end

Symbol = String
