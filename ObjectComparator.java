import java.lang.reflect.Field;
import java.util.HashMap;
import java.util.Map;

public class ObjectComparator {

    // Method to compare two objects and return the differences
    public static Map<String, String> compareObjects(Object obj1, Object obj2) throws IllegalAccessException {
        Map<String, String> differences = new HashMap<>();

        // If the objects are not of the same class, return the class names as a difference
        if (!obj1.getClass().equals(obj2.getClass())) {
            differences.put("Class Difference", obj1.getClass().getName() + " != " + obj2.getClass().getName());
            return differences;
        }

        // Get all fields of the class (including private fields)
        Field[] fields = obj1.getClass().getDeclaredFields();

        // Iterate through all fields and compare their values
        for (Field field : fields) {
            field.setAccessible(true); // Make the private fields accessible

            // Get the values of the fields from both objects
            Object value1 = field.get(obj1);
            Object value2 = field.get(obj2);

            // If the values are different, record the difference
            if ((value1 == null && value2 != null) || (value1 != null && !value1.equals(value2))) {
                differences.put(field.getName(), "obj1: " + value1 + ", obj2: " + value2);
            }
        }

        return differences;
    }

    public static void main(String[] args) throws IllegalAccessException {
        // Example usage with two sample objects

        // Sample objects to compare
        Person person1 = new Person("John", 25, "Engineer");
        Person person2 = new Person("John", 30, "Doctor");

        // Compare the objects
        Map<String, String> diff = compareObjects(person1, person2);

        // Print the differences
        if (diff.isEmpty()) {
            System.out.println("Objects are identical.");
        } else {
            diff.forEach((key, value) -> System.out.println(key + ": " + value));
        }
    }
}

class Person {
    private String name;
    private int age;
    private String profession;

    public Person(String name, int age, String profession) {
        this.name = name;
        this.age = age;
        this.profession = profession;
    }

    // Getters and setters
    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }

    public String getProfession() {
        return profession;
    }

    public void setProfession(String profession) {
        this.profession = profession;
    }
}
