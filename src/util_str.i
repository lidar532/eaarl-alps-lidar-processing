// vim: set ts=3 sts=3 sw=3 ai sr et:
require, "eaarl.i";

func atoi(str) {
/* DOCUMENT atoi(str)
   Converts a string representation of a number into an integer. For example:
      > atoi("12")
      12
      > atoi(["13.45", "-1000"])
      [13,-1000]
*/
   dims = dimsof(str);
   res = _rc_convert(str(*), 2, 0);
   return (dims(0) ? reform(res, dims) : res(1));
}

func atod(str) {
/* DOCUMENT atod(str)
   Converts a string representation of a number into a double. For example:
      > atod("3.14")
      3.14
      > atod(["-23.4", "43.1"])
      [-23.4,43.1]
*/
   dims = dimsof(str);
   res = _rc_convert(str(*), 3, 0.);
   return (dims(0) ? reform(res, dims) : res(1));
}

func atoc(str) {
/* DOCUMENT atoc(str)
   Converts a string representation of a char into a char. For example:
      > atoc("a")
      0x61
      > atoc(["a","b","c"])
      [0x61,0x62,0x63]
   Caveat: Every string element must be exactly one character in length.
*/
// Original David B. Nagle 2009-04-17
   if(anyof(strlen(str) != 1))
      error, "Input string elements must be exactly one character in length.";
   c = array(char, dimsof(str));
   for(i = 1; i <= numberof(str); i++) {
      c(i) = strchar(str(i))(1);
   }
   return c;
}

func strsplit(str, sep) {
/* DOCUMENT strsplit(str, sep)

   Given an input string (or array of strings), this will split the string(s)
   into arrays at each instance of the separator.

   A pair of separators with nothing between them results in "". If some of the
   strings in an array have more fields than others, the shorter-fielded ones
   will be padded with (nil).

   This will work only on one-dimensional arrays and scalar strings.

   Examples:

   > strsplit("hello,world", ",")
   ["hello","world"]

   > strsplit("foo,,bar", ",")
   ["foo","","bar"]

   > strsplit(["a b c", "1 2 3 4"], " ")
   [["a","1"],["b","2"],["c","3"],[(nil), "4"]]

   > strsplit("anythingSPLITcanSPLITseparate", "SPLIT")
   ["anything", "can", "separate"]

   In a one-dimensional array: If res is the result, then res(1,) contains the
   substrings for the first element, and res(,1) contains the first field of
   all elements.
*/
// Original David Nagle
   str = (str);
   match = [];
   parts = array(string, dimsof(str), 1);
   sep = regcomp(sep);
   res = regmatch(sep, str, match, indices=1);
   while(anyof(res)) {
      new = array(string, dimsof(str));
      w = where(match(1,) > 1 & res);
      if(numberof(w)) {
         idx = array(0, 2, numberof(w));
         idx(2,) = match(1,w) - 1;
         new(w) = strpart(str(w), idx);
         idx = array(0, 2, numberof(w));
         idx(1,) = match(2,w) - 1;
         idx(2,) = strlen(str(w));
         str(w) = strpart(str(w), idx);
      }
      w = where(match(1,) <= 1 & res);
      if(numberof(w)) {
         new(w) = "";
         idx = array(0, 2, numberof(w));
         idx(1,) = match(2,w) - 1;
         idx(2,) = strlen(str(w));
         str(w) = strpart(str(w), idx);
      }
      w = where(strlen(str) > 0 & !res);
      if(numberof(w)) {
         new(w) = str(w);
         str(w) = string(0);
      }
      grow, parts, new;
      res = regmatch(sep, str, match, indices=1);
   }
   w = where(strlen(str) > 0);
   if(numberof(w)) {
      new = array(string, dimsof(str));
      new(w) = str(w);
      grow, parts, new;
   }
   if(dimsof(parts)(1) > 1)
      return parts(,2:);
   else
      return parts(2:);
}

func strjoin2(lst, sep, stripnil=) {
/* DOCUMENT strjoin2(lst, sep, stripnil=)

   Given an input array of strings, this will join the strings into a single
   string, using the separator between each array item. If the array is not
   one-dimensional, it will be collapsed as str(*).

   If stripnil=1, then any nil values will be removed prior to joining.

   Example: strjoin2(["a", "b", "c"], "--") will return "a--b--c".

   See also: string
*/
   default, stripnil, 0;
   if(!numberof(lst)) return string(0);
   if(stripnil) {
      w = where(lst);
      if(!numberof(w))
         return string(0);
      lst = lst(w);
   }
   if(numberof(lst) > 1) {
      lst = lst(*);
      lst(:-1) += sep;
   }
   return lst(sum);
}

func strwrap(str, space=, newline=, paragraph=, width=) {
/* DOCUMENT wrapped = strwrap(str, space=, newline=, paragraph=, width=)
   Performs word-wrapping on the string defined by str.

   Options:
      space= Defaults to " ". This represets the string that delimits words.
      newline= Defaults to "\n". This represents the string the delimits lines.
      paragraph= Defaults to "\n\n". This represents the string the delimits
         paragraphs.
      width= Defaults 72. Specifies the maximum width for the wrapped text.
*/
// Original David B. Nagle 2009-04-03
   default, space, " ";
   default, newline, "\n";
   default, paragraph, "\n\n";
   default, width, 72;

   result = string(0);
   paragraphs = strsplit(str, paragraph);
   for(i = 1; i <= numberof(paragraphs); i++) {
      this_paragraph = string(0);
      this_line = string(0);
      lines = strsplit(paragraphs(i), newline);
      lines = strtrim(unref(lines));
      for(j = 1; j <= numberof(lines); j++) {
         words = strsplit(lines(j), space);
         for(k = 1; k <= numberof(words); k++) {
            trial_line = strjoin2([this_line, words(k)], space, stripnil=1);
            if(strlen(trial_line) <= width) {
               this_line = trial_line;
            } else {
               this_paragraph = strjoin2([this_paragraph, this_line], newline, stripnil=1);
               this_line = words(k);
            }
         }
      }
      if(strlen(this_line)) {
         this_paragraph = strjoin2([this_paragraph, this_line], newline, stripnil=1);
      }
      result = strjoin2([result, this_paragraph], paragraph, stripnil=1);
   }
   return result;
}

__strindent = regcomp("^(.*)$", newline=1);
func strindent(str, ind) {
/* DOCUMENT newstr = strindent(str, ind);
   Indents each line of str (as deliminted by newlines) with the indentation
   given by ind.
*/
// Original David B. Nagle 2009-04-09
   extern __strindent;
   return regsub(__strindent, str, ind + "\\1", all=1);
}

func longest_common_suffix(S) {
/* DOCUMENT suffix = longest_common_suffix(S)
   Returns the longest string that is a common suffix to all strings in S. If
   there is no common suffix, then string(0) is returned.
*/
// Original David Nagle 2009-12-28
   nS = numberof(S);
   if(nS == 0)
      return string(0);
   if(nS == 1)
      return S(1);

   s1 = strchar(S(1));
   for(i = 2; i <= nS; i++) {
      s2 = strchar(S(i));
      len = min(numberof(s1), numberof(s2));
      if(!len)
         return string(0);

      s1 = s1(1-len:);
      s2 = s2(1-len:);

      nomatch = s1 != s2;
      if(allof(nomatch))
         return string(0);

      last = noneof(nomatch) ? 0 : (nomatch * indgen(len))(mxx);
      if(last == len)
         return string(0);

      s1 = s1(last+1:);
   }
   return strchar(s1);
}

func base64_encode(input, maxlen=, wrapchar=) {
/* DOCUMENT encoded = base64_encode(input, maxlen=, wrapchar=)
   Uses base64 encoding to encode data.

   Parameter:
      input: Must be a scalar string or a one-dimensional char array.

   Options:
      maxlen= The maximum length for a single line in the encoded output. Lines
         will be broken with wrapchar at this length. Defaults to 76.
      wrapchar= The character to insert between lines, for wrapping. Defaults
         to \n.

   Output will be a scalar string.
*/
   default, maxlen, 76;
   default, wrapchar, '\n';

   base64_alphabet = char(grow(
      indgen(65:90),    // A-Z   0 to 25
      indgen(97:122),   // a-z   26 to 51
      indgen(48:57),    // 0-9   52 to 61
      43, 47            // +/    62 to 63
   ));

   if(typeof(input) == "string")
      data = strchar(input)(:-1);
   else if(typeof(input) == "char")
      data = input;
   else
      error, "Only accepts char and string input.";
   input = [];

   bitmod = numberof(data) % 3;

   if(bitmod)
      grow, data, array(char(0), 3 - bitmod);

   num_groups = numberof(data) / 3;

   data = reform(data, [2, 3, num_groups]);
   encoded = array(char, [2, 4, num_groups]);

   encoded(1,) = data(1,) >> 2;
   encoded(2,) = ((data(1,)&3)<<4) + (data(2,)>>4);
   encoded(3,) = ((data(2,)&15)<<2) + (data(3,)>>6);
   encoded(4,) = data(3,) & 63;

   encoded = reform(encoded, [1, numberof(encoded)]);
   indices = int(encoded) + 1;

   output = base64_alphabet(indices);
   if(bitmod == 1)
      output(-1:0) = ['=', '='];
   else if(bitmod == 2)
      output(0) = '=';

   if(numberof(output) > maxlen) {
      padding = maxlen - (numberof(output) % maxlen);
      padding = (padding == maxlen) ? 0 : padding;
      if(padding)
         grow, output, array(char, padding);
      output = reform(output, [2, maxlen, numberof(output) / maxlen]);
      output = transpose(grow(transpose(output), wrapchar));
      output = reform(output, [1, numberof(output)]);
      output = output(:-padding);
      output = output(:-numberof(wrapchar));
   }

   return strchar(output);
}

func base64_decode(input) {
/* DOCUMENT decoded = base64_decode(input)
   Decodes a string that was encoded using base64 encoding.

   Parameter:
      input: Must be a scalar string or a one-dimensional char array.

   Output will be an array of char data. (Pass to strchar to turn into a
   string.)
*/
// Rationale for returning char array instead of string:
// When passing through strchar, an array of char data ending with a single \0
// is treated the same as an array of char data ending without \0. Thus,
// passing the decoded output through strchar prior to returning would result
// in data loss in specific constrained circumstances.

   base64_alphabet = char(grow(
      indgen(65:90),    // A-Z   0 to 25
      indgen(97:122),   // a-z   26 to 51
      indgen(48:57),    // 0-9   52 to 61
      43, 47            // +/    62 to 63
   ));

   if(typeof(input) == "string")
      data = strchar(input)(:-1);
   else if(typeof(input) == "char")
      data = input;
   else
      error, "Only accepts char and string input.";
   input = [];

   encoded = array(char, numberof(data));
   gooddata = array(0, numberof(data));
   for(i = 1; i <= numberof(base64_alphabet); i++) {
      current = base64_alphabet(i);
      w = where(data == current);
      if(numberof(w)) {
         encoded(w) = i - 1;
         gooddata(w) = 1;
      }
   }
   w = where(data == '=');
   if(numberof(w)) {
      encoded(w) = 255;
      gooddata(w) = 1;
   }
   w = where(gooddata);
   if(numberof(w)) {
      encoded = encoded(w);
   } else {
      return "";
   }

   if(encoded(0) == 255) {
      if(encoded(-1) == 255) {
         bitmod = 1;
         encoded(-1) = 0;
         encoded(0) = 0;
      } else {
         bitmod = 2;
         encoded(0) = 0;
      }
   } else {
      bitmod = 3;
   }

   w = where(encoded == 255);
   if(numberof(w)) {
      error, "The = character was found in an illegal position.";
   }

   num_groups = numberof(encoded) / 4;

   data = array(char, [2, 3, num_groups]);
   encoded = reform(encoded, [2, 4, num_groups]);

   data(1,) = (encoded(1,) << 2) + (encoded(2,) >> 4);
   data(2,) = (encoded(2,) << 4) + (encoded(3,) >> 2);
   data(3,) = (encoded(3,) << 6) + encoded(4,);

   data = reform(data, [1, numberof(data)]);

   data = data(:bitmod-3);

   return data;
}
