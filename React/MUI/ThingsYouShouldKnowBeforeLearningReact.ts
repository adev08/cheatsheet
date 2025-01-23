// Things you should know before learning React

// 1. Destructing - Objects and Arrays
const user = {
    name: "John",
    age: 30,
    address: { city: "NY", country: "USA"}
};

// Basic destructuring
const { name, age } = user;

//Nested destructuring (common in complex props)
const { address: { city } } = user;

// Array destructuring (useState pattern);
const[first, second, ...rest] = [1, 2, 3, 4, 5];


// 2. Spread and Rest - State updates and props
const oldState = { name: 'John', age: 30};
const newState = { ...oldState, age: 31 };

//Rest in functions (collecting props)
const Button = ({ className, ...otherProps }) => {
    return <button className={className} {...otherProps} />;
};

