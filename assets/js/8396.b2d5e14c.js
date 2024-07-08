"use strict";(self.webpackChunknew_website=self.webpackChunknew_website||[]).push([[8396],{88396:(e,n,t)=>{t.r(n),t.d(n,{assets:()=>l,contentTitle:()=>o,default:()=>p,frontMatter:()=>r,metadata:()=>s,toc:()=>m});var a=t(87462),i=(t(67294),t(3905));t(45475);const r={title:"Generics",slug:"/types/generics"},o=void 0,s={unversionedId:"types/generics",id:"types/generics",title:"Generics",description:"Generics (sometimes referred to as polymorphic types) are a way of abstracting",source:"@site/docs/types/generics.md",sourceDirName:"types",slug:"/types/generics",permalink:"/en/docs/types/generics",draft:!1,editUrl:"https://github.com/facebook/flow/edit/main/website/docs/types/generics.md",tags:[],version:"current",frontMatter:{title:"Generics",slug:"/types/generics"},sidebar:"docsSidebar",previous:{title:"Interfaces",permalink:"/en/docs/types/interfaces"},next:{title:"Unions",permalink:"/en/docs/types/unions"}},l={},m=[{value:"Syntax of generics",id:"toc-syntax-of-generics",level:3},{value:"Functions with generics",id:"toc-functions-with-generics",level:3},{value:"Function types with generics",id:"toc-function-types-with-generics",level:3},{value:"Classes with generics",id:"toc-classes-with-generics",level:3},{value:"Type aliases with generics",id:"toc-type-aliases-with-generics",level:3},{value:"Interfaces with generics",id:"toc-interfaces-with-generics",level:3},{value:"Supplying Type Arguments to Callables",id:"toc-supplying-type-arguments-to-callables",level:3},{value:"Behavior of generics",id:"toc-behavior-of-generics",level:2},{value:"Generics act like variables",id:"toc-generics-act-like-variables",level:3},{value:"Create as many generics as you need",id:"toc-create-as-many-generics-as-you-need",level:3},{value:"Generics track values around",id:"toc-generics-track-values-around",level:3},{value:"Adding types to generics",id:"toc-adding-types-to-generics",level:3},{value:"Generic types act as bounds",id:"toc-generic-types-act-as-bounds",level:3},{value:"Parameterized generics",id:"toc-parameterized-generics",level:3},{value:"Adding defaults to parameterized generics",id:"toc-adding-defaults-to-parameterized-generics",level:3},{value:"Variance Sigils",id:"toc-variance-sigils",level:3}],c={toc:m};function p(e){let{components:n,...t}=e;return(0,i.mdx)("wrapper",(0,a.Z)({},c,t,{components:n,mdxType:"MDXLayout"}),(0,i.mdx)("p",null,"Generics (sometimes referred to as polymorphic types) are a way of abstracting\na type away."),(0,i.mdx)("p",null,"Imagine writing the following ",(0,i.mdx)("inlineCode",{parentName:"p"},"identity")," function which returns whatever value\nwas passed."),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-js"},"function identity(value) {\n  return value;\n}\n")),(0,i.mdx)("p",null,"We would have a lot of trouble trying to write specific types for this function\nsince it could be anything."),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},"function identity(value: string): string {\n  return value;\n}\n")),(0,i.mdx)("p",null,"Instead we can create a generic (or polymorphic type) in our function and use\nit in place of other types."),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},"function identity<T>(value: T): T {\n  return value;\n}\n")),(0,i.mdx)("p",null,"Generics can be used within functions, function types, classes, type aliases,\nand interfaces."),(0,i.mdx)("blockquote",null,(0,i.mdx)("p",{parentName:"blockquote"},(0,i.mdx)("strong",{parentName:"p"},"Warning:")," Flow does not infer generic types. If you want something to have a\ngeneric type, ",(0,i.mdx)("strong",{parentName:"p"},"annotate it"),". Otherwise, Flow may infer a type that is less\npolymorphic than you expect.")),(0,i.mdx)("h3",{id:"toc-syntax-of-generics"},"Syntax of generics"),(0,i.mdx)("p",null,"There are a number of different places where generic types appear in syntax."),(0,i.mdx)("h3",{id:"toc-functions-with-generics"},"Functions with generics"),(0,i.mdx)("p",null,"Functions can create generics by adding the type parameter list ",(0,i.mdx)("inlineCode",{parentName:"p"},"<T>")," before\nthe function parameter list."),(0,i.mdx)("p",null,"You can use generics in the same places you'd add any other type in a function\n(parameter or return types)."),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},"function method<T>(param: T): T {\n  return param;\n}\n\nconst f = function<T>(param: T): T {\n  return param;\n}\n")),(0,i.mdx)("h3",{id:"toc-function-types-with-generics"},"Function types with generics"),(0,i.mdx)("p",null,"Function types can create generics in the same way as normal functions, by\nadding the type parameter list ",(0,i.mdx)("inlineCode",{parentName:"p"},"<T>")," before the function type parameter list."),(0,i.mdx)("p",null,"You can use generics in the same places you'd add any other type in a function\ntype (parameter or return types)."),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-js"},"<T>(param: T) => T\n")),(0,i.mdx)("p",null,"Which then gets used as its own type."),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},"function method(func: <T>(param: T) => T) {\n  // ...\n}\n")),(0,i.mdx)("h3",{id:"toc-classes-with-generics"},"Classes with generics"),(0,i.mdx)("p",null,"Classes can create generics by placing the type parameter list before the body\nof the class."),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},"class Item<T> {\n  // ...\n}\n")),(0,i.mdx)("p",null,"You can use generics in the same places you'd add any other type in a class\n(property types and method parameter/return types)."),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},"class Item<T> {\n  prop: T;\n\n  constructor(param: T) {\n    this.prop = param;\n  }\n\n  method(): T {\n    return this.prop;\n  }\n}\n")),(0,i.mdx)("h3",{id:"toc-type-aliases-with-generics"},"Type aliases with generics"),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},"type Item<T> = {\n  foo: T,\n  bar: T,\n};\n")),(0,i.mdx)("h3",{id:"toc-interfaces-with-generics"},"Interfaces with generics"),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},"interface Item<T> {\n  foo: T,\n  bar: T,\n}\n")),(0,i.mdx)("h3",{id:"toc-supplying-type-arguments-to-callables"},"Supplying Type Arguments to Callables"),(0,i.mdx)("p",null,"You can give callable entities type arguments for their generics directly in the call:"),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},"function doSomething<T>(param: T): T {\n  // ...\n  return param;\n}\n\ndoSomething<number>(3);\n")),(0,i.mdx)("p",null,"You can also give generic classes type arguments directly in the ",(0,i.mdx)("inlineCode",{parentName:"p"},"new")," expression:"),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},"class GenericClass<T> {}\nconst c = new GenericClass<number>();\n")),(0,i.mdx)("p",null,"If you only want to specify some of the type arguments, you can use ",(0,i.mdx)("inlineCode",{parentName:"p"},"_")," to let flow infer a type for you:"),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},"class GenericClass<T, U=string, V=number>{}\nconst c = new GenericClass<boolean, _, string>();\n")),(0,i.mdx)("blockquote",null,(0,i.mdx)("p",{parentName:"blockquote"},(0,i.mdx)("strong",{parentName:"p"},"Warning:")," For performance purposes, we always recommend you annotate with\nconcrete arguments when you can. ",(0,i.mdx)("inlineCode",{parentName:"p"},"_")," is not unsafe, but it is slower than explicitly\nspecifying the type arguments.")),(0,i.mdx)("h2",{id:"toc-behavior-of-generics"},"Behavior of generics"),(0,i.mdx)("h3",{id:"toc-generics-act-like-variables"},"Generics act like variables"),(0,i.mdx)("p",null,"Generic types work a lot like variables or function parameters except that they\nare used for types. You can use them whenever they are in scope."),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},"function constant<T>(value: T): () => T {\n  return function(): T {\n    return value;\n  };\n}\n")),(0,i.mdx)("h3",{id:"toc-create-as-many-generics-as-you-need"},"Create as many generics as you need"),(0,i.mdx)("p",null,"You can have as many of these generics as you need in the type parameter list,\nnaming them whatever you want:"),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},"function identity<One, Two, Three>(one: One, two: Two, three: Three) {\n  // ...\n}\n")),(0,i.mdx)("h3",{id:"toc-generics-track-values-around"},"Generics track values around"),(0,i.mdx)("p",null,"When using a generic type for a value, Flow will track the value and make sure\nthat you aren't replacing it with something else."),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:'[{"startLine":2,"startColumn":10,"endLine":2,"endColumn":14,"description":"Cannot return `\\"foo\\"` because string [1] is incompatible with `T` [2]. [incompatible-return]"},{"startLine":5,"startColumn":10,"endLine":5,"endColumn":17,"description":"Cannot declare `identity` [1] because the name is already bound. [name-already-bound]"},{"startLine":6,"startColumn":11,"endLine":6,"endColumn":15,"description":"Cannot assign `\\"foo\\"` to `value` because string [1] is incompatible with `T` [2]. [incompatible-type]"},{"startLine":7,"startColumn":10,"endLine":7,"endColumn":14,"description":"Cannot return `value` because string [1] is incompatible with `T` [2]. [incompatible-return]"}]','[{"startLine":2,"startColumn":10,"endLine":2,"endColumn":14,"description":"Cannot':!0,return:!0,'`\\"foo\\"`':!0,because:!0,string:!0,"[1]":!0,is:!0,incompatible:!0,with:!0,"`T`":!0,"[2].":!0,'[incompatible-return]"},{"startLine":5,"startColumn":10,"endLine":5,"endColumn":17,"description":"Cannot':!0,declare:!0,"`identity`":!0,the:!0,name:!0,already:!0,"bound.":!0,'[name-already-bound]"},{"startLine":6,"startColumn":11,"endLine":6,"endColumn":15,"description":"Cannot':!0,assign:!0,to:!0,"`value`":!0,'[incompatible-type]"},{"startLine":7,"startColumn":10,"endLine":7,"endColumn":14,"description":"Cannot':!0,'[incompatible-return]"}]':!0},'function identity<T>(value: T): T {\n  return "foo"; // Error!\n}\n\nfunction identity<T>(value: T): T {\n  value = "foo"; // Error!\n  return value;  // Error!\n}\n')),(0,i.mdx)("p",null,"Flow tracks the specific type of the value you pass through a generic, letting\nyou use it later."),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:'[{"startLine":7,"startColumn":16,"endLine":7,"endColumn":27,"description":"Cannot assign `identity(...)` to `three` because number [1] is incompatible with number literal `3` [2]. [incompatible-type]"}]','[{"startLine":7,"startColumn":16,"endLine":7,"endColumn":27,"description":"Cannot':!0,assign:!0,"`identity(...)`":!0,to:!0,"`three`":!0,because:!0,number:!0,"[1]":!0,is:!0,incompatible:!0,with:!0,literal:!0,"`3`":!0,"[2].":!0,'[incompatible-type]"}]':!0},"function identity<T>(value: T): T {\n  return value;\n}\n\nlet one: 1 = identity(1);\nlet two: 2 = identity(2);\nlet three: 3 = identity(42); // Error\n")),(0,i.mdx)("h3",{id:"toc-adding-types-to-generics"},"Adding types to generics"),(0,i.mdx)("p",null,"Similar to  ",(0,i.mdx)("inlineCode",{parentName:"p"},"mixed"),', generics have an "unknown" type. You\'re not allowed to use\na generic as if it were a specific type.'),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:'[{"startLine":2,"startColumn":19,"endLine":2,"endColumn":21,"description":"Cannot get `obj.foo` because property `foo` is missing in mixed [1]. [incompatible-use]"}]','[{"startLine":2,"startColumn":19,"endLine":2,"endColumn":21,"description":"Cannot':!0,get:!0,"`obj.foo`":!0,because:!0,property:!0,"`foo`":!0,is:!0,missing:!0,in:!0,mixed:!0,"[1].":!0,'[incompatible-use]"}]':!0},"function logFoo<T>(obj: T): T {\n  console.log(obj.foo); // Error!\n  return obj;\n}\n")),(0,i.mdx)("p",null,"You could refine the type, but the generic will still allow any type to be\npassed in."),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},"function logFoo<T>(obj: T): T {\n  if (obj && obj.foo) {\n    console.log(obj.foo); // Works.\n  }\n  return obj;\n}\n\nlogFoo({ foo: 'foo', bar: 'bar' });  // Works.\nlogFoo({ bar: 'bar' }); // Works. :(\n")),(0,i.mdx)("p",null,"Instead, you could add a type to your generic like you would with a function\nparameter."),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:'[{"startLine":7,"startColumn":8,"endLine":7,"endColumn":21,"description":"Cannot call `logFoo` because property `foo` is missing in object literal [1] but exists in object type [2] in type argument `T`. [prop-missing]"}]','[{"startLine":7,"startColumn":8,"endLine":7,"endColumn":21,"description":"Cannot':!0,call:!0,"`logFoo`":!0,because:!0,property:!0,"`foo`":!0,is:!0,missing:!0,in:!0,object:!0,literal:!0,"[1]":!0,but:!0,exists:!0,type:!0,"[2]":!0,argument:!0,"`T`.":!0,'[prop-missing]"}]':!0},"function logFoo<T: {foo: string, ...}>(obj: T): T {\n  console.log(obj.foo); // Works!\n  return obj;\n}\n\nlogFoo({ foo: 'foo', bar: 'bar' });  // Works!\nlogFoo({ bar: 'bar' }); // Error!\n")),(0,i.mdx)("p",null,"This way you can keep the behavior of generics while only allowing certain\ntypes to be used."),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:'[{"startLine":7,"startColumn":31,"endLine":7,"endColumn":37,"description":"Cannot call `identity` because string [1] is incompatible with number [2] in type argument `T`. [incompatible-call]"}]','[{"startLine":7,"startColumn":31,"endLine":7,"endColumn":37,"description":"Cannot':!0,call:!0,"`identity`":!0,because:!0,string:!0,"[1]":!0,is:!0,incompatible:!0,with:!0,number:!0,"[2]":!0,in:!0,type:!0,argument:!0,"`T`.":!0,'[incompatible-call]"}]':!0},'function identity<T: number>(value: T): T {\n  return value;\n}\n\nlet one: 1 = identity(1);\nlet two: 2 = identity(2);\nlet three: "three" = identity("three"); // Error!\n')),(0,i.mdx)("h3",{id:"toc-generic-types-act-as-bounds"},"Generic types act as bounds"),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},"function identity<T>(val: T): T {\n  return val;\n}\n\nlet foo: 'foo' = 'foo';           // Works!\nlet bar: 'bar' = identity('bar'); // Works!\n")),(0,i.mdx)("p",null,'In Flow, most of the time when you pass one type into another you lose the\noriginal type. So that when you pass a specific type into a less specific one\nFlow "forgets" it was once something more specific.'),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:'[{"startLine":6,"startColumn":18,"endLine":6,"endColumn":32,"description":"Cannot assign `identity(...)` to `bar` because string [1] is incompatible with string literal `bar` [2]. [incompatible-type]"}]','[{"startLine":6,"startColumn":18,"endLine":6,"endColumn":32,"description":"Cannot':!0,assign:!0,"`identity(...)`":!0,to:!0,"`bar`":!0,because:!0,string:!0,"[1]":!0,is:!0,incompatible:!0,with:!0,literal:!0,"[2].":!0,'[incompatible-type]"}]':!0},"function identity(val: string): string {\n  return val;\n}\n\nlet foo: 'foo' = 'foo';           // Works!\nlet bar: 'bar' = identity('bar'); // Error!\n")),(0,i.mdx)("p",null,'Generics allow you to hold onto the more specific type while adding a\nconstraint. In this way types on generics act as "bounds".'),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},"function identity<T: string>(val: T): T {\n  return val;\n}\n\nlet foo: 'foo' = 'foo';           // Works!\nlet bar: 'bar' = identity('bar'); // Works!\n")),(0,i.mdx)("p",null,"Note that when you have a value with a bound generic type, you can't use it as\nif it were a more specific type."),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:'[{"startLine":3,"startColumn":21,"endLine":3,"endColumn":23,"description":"Cannot assign `val` to `bar` because string [1] is incompatible with string literal `bar` [2]. [incompatible-type]"}]','[{"startLine":3,"startColumn":21,"endLine":3,"endColumn":23,"description":"Cannot':!0,assign:!0,"`val`":!0,to:!0,"`bar`":!0,because:!0,string:!0,"[1]":!0,is:!0,incompatible:!0,with:!0,literal:!0,"[2].":!0,'[incompatible-type]"}]':!0},"function identity<T: string>(val: T): T {\n  let str: string = val; // Works!\n  let bar: 'bar'  = val; // Error!\n  return val;\n}\n\nidentity('bar');\n")),(0,i.mdx)("h3",{id:"toc-parameterized-generics"},"Parameterized generics"),(0,i.mdx)("p",null,"Generics sometimes allow you to pass types in like arguments to a function.\nThese are known as parameterized generics (or parametric polymorphism)."),(0,i.mdx)("p",null,"For example, a type alias with a generic is parameterized. When you go to use\nit you will have to provide a type argument."),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},'type Item<T> = {\n  prop: T,\n}\n\nlet item: Item<string> = {\n  prop: "value"\n};\n')),(0,i.mdx)("p",null,"You can think of this like passing arguments to a function, only the return\nvalue is a type that you can use."),(0,i.mdx)("p",null,"Classes (when being used as a type), type aliases, and interfaces all require\nthat you pass type arguments. Functions and function types do not have\nparameterized generics."),(0,i.mdx)("p",null,(0,i.mdx)("strong",{parentName:"p"},(0,i.mdx)("em",{parentName:"strong"},"Classes"))),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",1:!0,className:"language-flow",metastring:'[{"startLine":9,"startColumn":12,"endLine":9,"endColumn":15,"description":"Cannot use `Item` [1] without 1 type argument. [missing-type-arg]"}]','[{"startLine":9,"startColumn":12,"endLine":9,"endColumn":15,"description":"Cannot':!0,use:!0,"`Item`":!0,"[1]":!0,without:!0,type:!0,"argument.":!0,'[missing-type-arg]"}]':!0},"class Item<T> {\n  prop: T;\n  constructor(param: T) {\n    this.prop = param;\n  }\n}\n\nlet item1: Item<number> = new Item(42); // Works!\nlet item2: Item = new Item(42); // Error!\n")),(0,i.mdx)("p",null,(0,i.mdx)("strong",{parentName:"p"},(0,i.mdx)("em",{parentName:"strong"},"Type Aliases"))),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",1:!0,className:"language-flow",metastring:'[{"startLine":6,"startColumn":12,"endLine":6,"endColumn":15,"description":"Cannot use `Item` [1] without 1 type argument. [missing-type-arg]"}]','[{"startLine":6,"startColumn":12,"endLine":6,"endColumn":15,"description":"Cannot':!0,use:!0,"`Item`":!0,"[1]":!0,without:!0,type:!0,"argument.":!0,'[missing-type-arg]"}]':!0},"type Item<T> = {\n  prop: T,\n};\n\nlet item1: Item<number> = { prop: 42 }; // Works!\nlet item2: Item = { prop: 42 }; // Error!\n")),(0,i.mdx)("p",null,(0,i.mdx)("strong",{parentName:"p"},(0,i.mdx)("em",{parentName:"strong"},"Interfaces"))),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",1:!0,className:"language-flow",metastring:'[{"startLine":10,"startColumn":19,"endLine":10,"endColumn":25,"description":"Cannot use `HasProp` [1] without 1 type argument. [missing-type-arg]"}]','[{"startLine":10,"startColumn":19,"endLine":10,"endColumn":25,"description":"Cannot':!0,use:!0,"`HasProp`":!0,"[1]":!0,without:!0,type:!0,"argument.":!0,'[missing-type-arg]"}]':!0},"interface HasProp<T> {\n  prop: T,\n}\n\nclass Item {\n  prop: string;\n}\n\nItem.prototype as HasProp<string>; // Works!\nItem.prototype as HasProp; // Error!\n")),(0,i.mdx)("h3",{id:"toc-adding-defaults-to-parameterized-generics"},"Adding defaults to parameterized generics"),(0,i.mdx)("p",null,"You can also provide defaults for parameterized generics just like parameters\nof a function."),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},"type Item<T: number = 1> = {\n  prop: T,\n};\n\nlet foo: Item<> = { prop: 1 };\nlet bar: Item<2> = { prop: 2 };\n")),(0,i.mdx)("p",null,"You must always include the brackets ",(0,i.mdx)("inlineCode",{parentName:"p"},"<>")," when using the type (just like\nparentheses for a function call)."),(0,i.mdx)("h3",{id:"toc-variance-sigils"},"Variance Sigils"),(0,i.mdx)("p",null,"You can also specify the subtyping behavior of a generic via variance sigils.\nBy default, generics behave invariantly, but you may add a ",(0,i.mdx)("inlineCode",{parentName:"p"},"+")," to their\ndeclaration to make them behave covariantly, or a ",(0,i.mdx)("inlineCode",{parentName:"p"},"-")," to their declaration to\nmake them behave contravariantly. See ",(0,i.mdx)("a",{parentName:"p",href:"../../lang/variance"},"our docs on variance"),"\nfor a more information on variance in Flow."),(0,i.mdx)("p",null,"Variance sigils allow you to be more specific about how you intend to\nuse your generics, giving Flow the power to do more precise type checking.\nFor example, you may want this relationship to hold:"),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:"[]","[]":!0},"type GenericBox<+T> = T;\n\nconst x: GenericBox<number> = 3;\nx as GenericBox<number| string>;\n")),(0,i.mdx)("p",null,"The example above could not be accomplished without the ",(0,i.mdx)("inlineCode",{parentName:"p"},"+")," variance sigil:"),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:'[{"startLine":4,"startColumn":1,"endLine":4,"endColumn":1,"description":"Cannot cast `x` to `GenericBoxError` because string [1] is incompatible with number [2] in type argument `T` [3]. [incompatible-cast]"}]','[{"startLine":4,"startColumn":1,"endLine":4,"endColumn":1,"description":"Cannot':!0,cast:!0,"`x`":!0,to:!0,"`GenericBoxError`":!0,because:!0,string:!0,"[1]":!0,is:!0,incompatible:!0,with:!0,number:!0,"[2]":!0,in:!0,type:!0,argument:!0,"`T`":!0,"[3].":!0,'[incompatible-cast]"}]':!0},"type GenericBoxError<T> = T;\n\nconst x: GenericBoxError<number> = 3;\nx as GenericBoxError<number| string>; // number | string is not compatible with number.\n")),(0,i.mdx)("p",null,"Note that if you annotate your generic with variance sigils then Flow will\ncheck to make sure those types only appear in positions that make sense for\nthat variance sigil. For example, you cannot declare a generic type parameter\nto behave covariantly and use it in a contravariant position:"),(0,i.mdx)("pre",null,(0,i.mdx)("code",{parentName:"pre",className:"language-flow",metastring:'[{"startLine":1,"startColumn":34,"endLine":1,"endColumn":34,"description":"Cannot use `T` [1] in an input position because `T` [1] is expected to occur only in output positions. [incompatible-variance]"}]','[{"startLine":1,"startColumn":34,"endLine":1,"endColumn":34,"description":"Cannot':!0,use:!0,"`T`":!0,"[1]":!0,in:!0,an:!0,input:!0,position:!0,because:!0,is:!0,expected:!0,to:!0,occur:!0,only:!0,output:!0,"positions.":!0,'[incompatible-variance]"}]':!0},"type NotActuallyCovariant<+T> = (T) => void;\n")))}p.isMDXComponent=!0}}]);