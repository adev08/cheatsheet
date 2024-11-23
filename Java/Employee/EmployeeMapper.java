import org.mapstruct.*;



// Using MapStruct to map between the Employee entity and EmployeeDTO:

@Mapper(componentModel = "spring")
public interface EmployeeMapper {

    EmployeeDTO toDTO(Employee employee);

    Employee toEntity(EmployeeDTO employeeDTO);
}


