chai = require 'chai'; chai.should(); expect = chai.expect

compile = require '../lib/compile'

describe '#compile', ->
  describe 'Comments', ->
    it 'should convert # comments to //', ->
      line = "# commented line"
      compile(line).should.eq '// commented line'
    it 'should allow JS comments', ->
      line = "// commented line"
      compile(line).should.eq '// commented line'
    it 'should not skip comments that are in the middle', ->
      line = "something # commented line"
      compile(line).should.eq 'something // commented line'
    it 'should not process line that starts with a comment', ->
      line = "  # commented do"
      compile(line).should.eq '  // commented do'
    it 'should not comment out # inside a string', ->
      line = " $('#someClass') "
      compile(line).should.eq " $('#someClass') "

  describe '@ symbol', ->
    it 'should alias this', ->
      compile('@prop').should.eq  'this.prop'
      compile('@_prop').should.eq 'this._prop'
      compile('@$prop').should.eq 'this.$prop'
    it 'should work when @ is floating?', ->
      line = 'function (callBack, @)'
      compile(line).should.eq 'function (callBack, this)'
      line = 'function (callBack, @ )'
      compile(line).should.eq 'function (callBack, this )'
    it 'should work with a trailling dot', ->
      compile('@.foo').should.eq 'this.foo'
      compile('@.foo @bar').should.eq 'this.foo this.bar'
      compile('@_foo').should.eq 'this._foo'
      compile('@$foo').should.eq 'this.$foo'
    it 'should work when two @ are used', ->
      compile('@prop1 = @prop2').should.eq 'this.prop1 = this.prop2'
  
  describe 'do end aliases', ->
      #it 'should alias correctly', ->
        #line = '''
        #function foo() do
        #end
        #'''
        #compile(line).should.eq '''
        #function foo() {
        #}
        #'''
      it 'should not alias a do loop', ->
        line = 'do { '
        compile(line).should.eq 'do { '
      #it 'should pass when used on a single line', ->
        #line = 'function foo() do return 1*2 end'
        #compile(line).should.eq 'function foo() { return 1*2 }'
        #compile(' do end ').should.eq ' { } '
      it 'should pass lookbehind tests', ->
        compile('doing').should.eq 'doing'
        compile('ending').should.eq 'ending'
      it 'should not transform strings'
        #compile(' "my string do and end "').should.eq ' "my string do and end "'

  describe 'kludgey end- alias', ->
    it 'should alias `end-` `end);`', ->
      compile('end-').should.eq '});'
      

  describe '#puts', ->
    it 'should pass with parens', ->
      compile('puts(foo)').should.eq 'console.log(foo)'
      compile('puts(method(param))').should.eq 'console.log(method(param))'
    it 'should pass without parens', ->
      compile('puts foo').should.eq 'console.log(foo);'
      compile('puts "bar"').should.eq 'console.log("bar");'
      compile('puts(foo); puts "bar"').should.eq 'console.log(foo); console.log("bar");'
      compile('puts method(param)').should.eq 'console.log(method(param));'

  describe '#printf', ->
    it 'should pass with parens', ->
      compile('printf(foo)').should.eq 'process.stdout.write(foo)'
      compile('printf(method(param))').should.eq 'process.stdout.write(method(param))'
    it 'should pass without parens', ->
      compile('printf foo').should.eq 'process.stdout.write(foo);'
      compile('printf "bar"').should.eq 'process.stdout.write("bar");'
      compile('printf(foo); printf "bar"').should.eq 'process.stdout.write(foo); process.stdout.write("bar");'
      compile('printf method(param)').should.eq 'process.stdout.write(method(param));'

  describe 'func', ->
    it 'should alias to function using parens', ->
      compile('func foo()').should.eq 'var foo = function() {'
      compile('func $bar(foo)').should.eq 'var $bar = function(foo) {'
      compile('func $bar(foo, bar)').should.eq 'var $bar = function(foo, bar) {'
    it 'should alias to function with bang and question chars'
      #compile('func hasUser?()').should.eq 'var hasUser_Q = function() {'
      #compile('func replace!()').should.eq 'var replace_B = function() {'
    it 'should have optional parens', ->
      compile('func bar').should.eq 'var bar = function() {'
      compile('func $_bar').should.eq 'var $_bar = function() {'
  
  describe 'switch statement', ->
    it 'should compile properly', ->
      redSwitch = '''
        switch fruit()
        when "Oranges"
          alert("oranges");
          break;
        when "Apples" then alert()
        default
          alert("something")
        end
      '''
      compile(redSwitch).should.eq '''
        switch (fruit()) {
        case "Oranges":
          alert("oranges");
          break;
        case "Apples" : alert() ; break;
        default:
          alert("something")
        }
      '''
  
  describe 'if statement', ->
    it 'should alias to if with parens', ->
      line = 'if foo === 10'
      compile(line).should.eq 'if (foo === 10) {'
    it 'should not transform if with parens', ->
      compile('if (err) throw err;').should.eq 'if (err) throw err;'
      compile('if (foo === 10) {').should.eq 'if (foo === 10) {'
    it 'should not convert strings', ->
      compile(' "foo b if  bar" ').should.eq ' "foo b if  bar" '
      compile(' "i saw a gif on reddit" ').should.eq ' "i saw a gif on reddit" '

  describe 'else statement', ->
    it 'should transform to else with brackets', ->
      compile('else').should.eq '} else {'
      compile('  else  ').should.eq '  } else {  '
    it 'should not transform if it already has brackets', ->
      compile('else {').should.eq 'else {'
      compile('} else {').should.eq '} else {'
      compile('}else{').should.eq '}else{'
      compile('}  else   {').should.eq '}  else   {'
    it 'should not transform an else if statement', ->
      compile('else if ').should.eq 'else if '
    it 'should not convert strings', ->
      compile(' "foo else b else  bar" ').should.eq ' "foo else b else  bar" '

  describe 'elsif statement', ->
    it 'should transform to else if with brackets', ->
      compile('elsif foo').should.eq '} else if (foo) {'
      compile('  elsif foo').should.eq '  } else if (foo) {'
      compile('elsif foo === 20').should.eq '} else if (foo === 20) {'
    it 'should not convert strings', ->
      compile(' "foo elsif baz bar" ').should.eq ' "foo elsif baz bar" '

  describe 'else if statement', ->
    it 'should transform to else if with brackets', ->
      compile('else if foo').should.eq '} else if (foo) {'
      compile('  else if foo').should.eq '  } else if (foo) {'
      compile('else if foo === 20').should.eq '} else if (foo === 20) {'
    it 'should not transform if it already has parens', ->
      compile('} else if (foo === 20) {').should.eq '} else if (foo === 20) {'
      compile('} else if (foo){').should.eq '} else if (foo){'
    it 'should not convert strings', ->
      compile(' "foo else if baz bar" ').should.eq ' "foo else if baz bar" '

  describe 'string interpolation', ->
    it 'should convert to string concatination', ->
      line = '"Hello #{name}, how are you?"'
      compile(line).should.eq '"Hello " + name + ", how are you?"'

    it 'should not concat right side if interp is on right edge of quotes', ->
      line = '''
      "Hello #{name}"
      '''
      compile(line).should.eq '''
      "Hello " + name
      '''
    it 'should not concat left side if interp is on left edge of quotes', ->
      line = '''
      "#{name} Hello"
      '''
      compile(line).should.eq '''
      name + " Hello"
      '''
    it 'should wrap scary interpolated chars inside parens', ->
      line = '''
      "#{foo + bar} Hello"
      '''
      compile(line).should.eq '''
      (foo + bar) + " Hello"
      '''
    it 'should wrap scary interpolated chars inside parens', ->
      line = '''
      "foo #{2 * 3 - 3 / 7 % 2} Hello"
      '''
      compile(line).should.eq '''
      "foo " + (2 * 3 - 3 / 7 % 2) + " Hello"
      '''
  describe 'anonymous function block', ->
    it 'should work without params', ->
      compile('on("change", do').should.eq 'on("change", function() {'
      compile('method( do').should.eq 'method( function() {'
    it 'should work with params', ->
      compile('method( do |x|').should.eq 'method( function(x) {'
      compile('method( do |x,y|').should.eq 'method( function(x,y) {'
      line = 'readFile("passwd", do |err, data|'
      compile(line).should.eq 'readFile("passwd", function(err, data) {'
    it 'should work without a preceding comma', ->
      line = 'get("/users/:user" do |x|'
      compile(line).should.eq 'get("/users/:user" , function(x) {'
      line = 'get("/users/:user" do'
      compile(line).should.eq 'get("/users/:user" , function() {'

  describe 'object litteral', ->
    it 'should transform to vanilla object syntax', ->
      compile('object objectName').should.eq 'var objectName = {'
      compile('  object _$Bar').should.eq '  var _$Bar = {'
    it 'should not transform object inside of strings', ->
      compile(' "i love object lamp" ').should.eq ' "i love object lamp" '

  describe 'def methods', ->
    it 'should work with parens inside an object literal', ->
      compile('def foo(p1, p2)').should.eq 'foo: function(p1, p2) {'
      compile('def Bo_$o()').should.eq 'Bo_$o: function() {'
    it 'should work without parens inside an object literal', ->
      compile('def foo').should.eq 'foo: function() {'
      compile('def Bo_$o').should.eq 'Bo_$o: function() {'
    it 'should not transform `def foo.bar` or `def foo >> bar`'
      #compile('def foo.bar').should.eq 'def foo.bar'
      #compile('def Bo_$o >>> baz').should.eq 'def Bo_$o >>> baz'
    it 'should transform def default properly', ->
      compile('def default').should.eq 'default: function() {'

  describe 'def foo.bar methods', ->
    it 'should work with parens', ->
      compile('def foo.bar(p1, p2)').should.eq 'foo.bar = function(p1, p2) {'
      compile('def foo.Bo_$o()').should.eq 'foo.Bo_$o = function() {'
    it 'should work without parens inside an object literal', ->
      compile('def foo.bar').should.eq 'foo.bar = function() {'
      compile('def foo.Bo_$o').should.eq 'foo.Bo_$o = function() {'

  describe 'def proto methods', ->
    it 'should work with parens', ->
      compile('def foo >> bar(p1, p2)').should.eq 'foo.prototype.bar = function(p1, p2) {'
      compile('def foo >> Bo_$o()').should.eq 'foo.prototype.Bo_$o = function() {'
    it 'should work without parens inside an object literal', ->
      compile('def foo >> bar').should.eq 'foo.prototype.bar = function() {'
      compile('def foo >> Bo_$o').should.eq 'foo.prototype.Bo_$o = function() {'

  describe 'Conditional Assigment Operator', ->
    it 'should work', ->
      compile('app ||= {}').should.eq 'app = app || {}'
      compile('foo ||= bar').should.eq 'foo = foo || bar'
      compile('foo   ||=   bar').should.eq 'foo = foo || bar'
      compile('_foo ||= b$_ar').should.eq '_foo = _foo || b$_ar'
      # Regex test cases: http://gskinner.com/RegExr/?33qm8
  
  describe 'Bracketless for in', ->
    it 'should compile without conflicts', ->
      compile('for key in obbj').should.eq 'for (var key in obbj) {'
      
