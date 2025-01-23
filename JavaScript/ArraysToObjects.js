//Convert Arrays to Objects


//Using Object.fromEntries()
const array = [['name', 'John'], ['age', 30]];
const obj = Object.fromEntries(array);
console.log(obj); // { name: 'John', age: 30 }


//Using Object.assign()
const obj = {};
const array = [['name', 'John'], ['age', 30]];
Object.assign(obj, ...array.map(([key, value]) => ({ [key]: value })));
console.log(obj); // { name: 'John', age: 30 }


//Using a loop
const obj = {};
const array = [['name', 'John'], ['age', 30]];
array.forEach(([key, value]) => obj[key] = value);
console.log(obj); // { name: 'John', age: 30 }


//Using reduce()
const array = [['name', 'John'], ['age', 30]];
const obj = array.reduce((acc, [key, value]) => ({ ...acc, [key]: value }), {});
console.log(obj); // { name: 'John', age: 30 }


//Using a library like Lodash
const _ = require('lodash');
const array = [['name', 'John'], ['age', 30]];
const obj = _.pick({}, array.map(([key, value]) => ({ [key]: value })));
console.log(obj); // { name: 'John', age: 30 }