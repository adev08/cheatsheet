

private record User(string name, Strring address) {}
var user = new User("Alex", null);

//Instance of...
public String getAddressFromUser_Bad(User user) {
    Optional<String> optionalAddress = Optional.ofNullable(user.address());
    if(optionalAddress.isPresent()){
        return optionalAddress.get();
    }

    return addressProvider.lookup(user);
}


// Do this... if you want to return a constant value
public String getAddressFromUser_orConstantValue(User user) {
    return Optional.ofNullable(user.address).orElse("Unknown Address");
}

// Do this... if you want to run logic when null
public String getAddressFromUser_orAlternativeLogic(User user) {
    ruturn Optional.orNullable(user.address).orElse(() -> {
        new addressProvider.lookup(user)});
}

// Do this... if you want to throw an exception when null
public String getAddressFromUser_orThrowException(User user) {
    ruturn Optional.orNullable(user.address).orElse(() -> {
        new MissingAddressException("Address not found for user " + user.name());
    })
}