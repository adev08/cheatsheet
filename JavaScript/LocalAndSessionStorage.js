
// Local Storage (Data persist across sessions)

localStorage.setItem('key', 'value');                       // Store data in local storage
let value = localStorage.getItem('key');                    // Retrieve data from local storage
localStorage.removeItem('key');                             // Remove specific item
localStorage.clear();                                       // Remove all items in local storage
localStorage.length;                                        // Get number of stored items
let key = localStorage.key(0);                              // Get the key name of the first items



// Session  Storage (Data persists only during the session)

sessionStorage.setItem('key', 'value');                       // Store data in session storage
let sessionValue = sessionStorage.getItem('key');             // Retrieve data from session storage
sessionStorage.removeItem('key');                             // Remove specific item
sessionStorage.clear();                                       // Remove all items in session storage
sessionStorage.length;                                        // Get number of stored items
let sessionKey = sessionStorage.key(0);                       // Get the key name of the first items


// Storing and Restrieving Objects (Local and Session Storage)

//Storing an object (convert to string first)
let obj = {name: "John", age: 30 };
localStorage.setItem('user', JSON.stringify(obj));

// Retrieving an object (parse the string back to the object)
let retrieveObj = JSON.parse(localStorage.getItem('user'));

// Similarly for session storage
sessionStorage.setItem('user', JSON.stringify(obj));
let sessionObj = JSON.parse(localStorage.getItem('user'));