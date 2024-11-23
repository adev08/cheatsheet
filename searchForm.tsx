// import React, { useState } from "react";
// import { TextField, Button, Grid, Box } from "@mui/material";

// const initialData = [
//   { id: 1, firstname: "John", lastname: "Doe", userid: "jdoe" },
//   { id: 2, firstname: "Jane", lastname: "Smith", userid: "jsmith" },
//   { id: 3, firstname: "Sam", lastname: "Green", userid: "sgreen" },
//   { id: 4, firstname: "Emily", lastname: "White", userid: "ewhite" },
// ];

// const SearchForm = () => {
//   const [searchParams, setSearchParams] = useState({
//     lastname: "",
//     firstname: "",
//     userid: "",
//   });

//   const [filteredData, setFilteredData] = useState(initialData);

//   const handleSearchChange = (e) => {
//     const { name, value } = e.target;
//     setSearchParams((prevParams) => ({
//       ...prevParams,
//       [name]: value,
//     }));
//   };

//   const handleSearch = () => {
//     const { lastname, firstname, userid } = searchParams;
//     const filteredResults = initialData.filter((user) =>
//       (lastname ? user.lastname.toLowerCase().includes(lastname.toLowerCase()) : true) &&
//       (firstname ? user.firstname.toLowerCase().includes(firstname.toLowerCase()) : true) &&
//       (userid ? user.userid.toLowerCase().includes(userid.toLowerCase()) : true)
//     );
//     setFilteredData(filteredResults);
//     console.log(lastname)
//   };

//   return (
//     <div>
//       <Box sx={{ padding: 3 }}>
//         <Grid container spacing={2}>
//           <Grid item xs={4}>
//             <TextField
//               label="Lastname"
//               name="lastname"
//               value={searchParams.lastname}
//               onChange={handleSearchChange}
//               fullWidth
//             />
//           </Grid>
//           <Grid item xs={4}>
//             <TextField
//               label="Firstname"
//               name="firstname"
//               value={searchParams.firstname}
//               onChange={handleSearchChange}
//               fullWidth
//             />
//           </Grid>
//           <Grid item xs={4}>
//             <TextField
//               label="UserID"
//               name="userid"
//               value={searchParams.userid}
//               onChange={handleSearchChange}
//               fullWidth
//             />
//           </Grid>
//         </Grid>

//         <Box sx={{ marginTop: 2 }}>
//           <Button variant="contained" onClick={handleSearch}>
//             Search
//           </Button>
//         </Box>
//       </Box>

//       <Box sx={{ padding: 3 }}>
//         <h3>Search Results:</h3>
//         <ul>
//           {filteredData.map((user) => (
//             <li key={user.id}>
//               {user.firstname} {user.lastname} ({user.userid})
//             </li>
//           ))}
//         </ul>
//       </Box>
//     </div>
//   );
// };

// export default SearchForm;


// import React, { useState } from "react";
// import { TextField, Button, Grid, Box } from "@mui/material";
// import { useForm } from "react-hook-form";

// // Sample data for the table
// const initialData = [
//   { id: 1, firstname: "John", lastname: "Doe", userid: "jdoe" },
//   { id: 2, firstname: "Jane", lastname: "Smith", userid: "jsmith" },
//   { id: 3, firstname: "Sam", lastname: "Green", userid: "sgreen" },
//   { id: 4, firstname: "Emily", lastname: "White", userid: "ewhite" },
// ];

// const SearchForm = () => {
//   const { register, handleSubmit, setValue } = useForm();
//   const [filteredData, setFilteredData] = useState(initialData);

//   // Handle the form submission and filter the data based on search criteria
//   const onSubmit = (data) => {
//     const { lastname, firstname, userid } = data;

//     if(data) {
//       if(userid) {
//         console.log(userid)
//       }
//       if(lastname && !firstname) {
//         console.log(lastname)
//       }
//       if(firstname && !lastname) {
//         console.log(firstname)
//       }
//       if(firstname && lastname) {
//         console.log(firstname + " " + lastname)
//       }
//     }

//     // Filtering the data based on the search parameters
//     const filteredResults = initialData.filter((user) =>
      
//       (lastname ? user.lastname.toLowerCase().includes(lastname.toLowerCase()) : true) &&
//       (firstname ? user.firstname.toLowerCase().includes(firstname.toLowerCase()) : true) &&
//       (userid ? user.userid.toLowerCase().includes(userid.toLowerCase()) : true)
//     );
//     setFilteredData(filteredResults);
//   };

//   return (
//     <div>
//       <Box sx={{ padding: 3 }}>
//         <form onSubmit={handleSubmit(onSubmit)}>
//           <Grid container spacing={2}>
//             <Grid item xs={4}>
//               <TextField
//                 label="Lastname"
//                 fullWidth
//                 {...register("lastname")}
//               />
//             </Grid>
//             <Grid item xs={4}>
//               <TextField
//                 label="Firstname"
//                 fullWidth
//                 {...register("firstname")}
//               />
//             </Grid>
//             <Grid item xs={4}>
//               <TextField
//                 label="UserID"
//                 fullWidth
//                 {...register("userid")}
//               />
//             </Grid>
//           </Grid>

//           <Box sx={{ marginTop: 2 }}>
//             <Button variant="contained" type="submit">
//               Search
//             </Button>
//           </Box>
//         </form>
//       </Box>

//       <Box sx={{ padding: 3 }}>
//         <h3>Search Results:</h3>
//         <ul>
//           {filteredData.map((user) => (
//             <li key={user.id}>
//               {user.firstname} {user.lastname} ({user.userid})
//             </li>
//           ))}
//         </ul>
//       </Box>
//     </div>
//   );
// };

// export default SearchForm;


import React, { useState } from "react";
import { TextField, Button, Grid, Box, Typography } from "@mui/material";
import { useForm, Controller } from "react-hook-form";

// Sample data for the table
const initialData = [
  { id: 1, firstname: "John", lastname: "Doe", userid: "jdoe" },
  { id: 2, firstname: "Jane", lastname: "Smith", userid: "jsmith" },
  { id: 3, firstname: "Sam", lastname: "Green", userid: "sgreen" },
  { id: 4, firstname: "Emily", lastname: "White", userid: "ewhite" },
];

const SearchForm = () => {
  const { control, handleSubmit, formState: { errors }, reset } = useForm();
  const [filteredData, setFilteredData] = useState(initialData);

  // Handle the form submission and filter the data based on search criteria
  const onSubmit = (data) => {
    const { lastname, firstname, userid } = data;

    // Filtering the data based on the search parameters
    const filteredResults = initialData.filter((user) =>
      (lastname ? user.lastname.toLowerCase().includes(lastname.toLowerCase()) : true) &&
      (firstname ? user.firstname.toLowerCase().includes(firstname.toLowerCase()) : true) &&
      (userid ? user.userid.toLowerCase().includes(userid.toLowerCase()) : true)
    );
    setFilteredData(filteredResults);
  };

  return (
    <div>
      <Box sx={{ padding: 3 }}>
        <form onSubmit={handleSubmit(onSubmit)}>
          <Grid container spacing={2}>
            <Grid item xs={4}>
              <Controller
                name="lastname"
                control={control}
                rules={{ required: "Lastname is required" }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Lastname"
                    fullWidth
                    error={!!errors.lastname}
                    helperText={errors.lastname ? errors.lastname.message : ""}
                  />
                )}
              />
            </Grid>
            <Grid item xs={4}>
              <Controller
                name="firstname"
                control={control}
                rules={{ required: "Firstname is required" }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="Firstname"
                    fullWidth
                    error={!!errors.firstname}
                    helperText={errors.firstname ? errors.firstname.message : ""}
                  />
                )}
              />
            </Grid>
            <Grid item xs={4}>
              <Controller
                name="userid"
                control={control}
                rules={{
                  required: "User ID is required",
                  minLength: {
                    value: 3,
                    message: "User ID must be at least 3 characters long",
                  },
                }}
                render={({ field }) => (
                  <TextField
                    {...field}
                    label="UserID"
                    fullWidth
                    error={!!errors.userid}
                    helperText={errors.userid ? errors.userid.message : ""}
                  />
                )}
              />
            </Grid>
          </Grid>

          <Box sx={{ marginTop: 2 }}>
            <Button variant="contained" type="submit">
              Search
            </Button>
            <Button
              variant="outlined"
              onClick={() => reset()} // Reset form values on clicking reset button
              sx={{ marginLeft: 2 }}
            >
              Reset
            </Button>
          </Box>
        </form>
      </Box>

      <Box sx={{ padding: 3 }}>
        <Typography variant="h6">Search Results:</Typography>
        <ul>
          {filteredData.length > 0 ? (
            filteredData.map((user) => (
              <li key={user.id}>
                {user.firstname} {user.lastname} ({user.userid})
              </li>
            ))
          ) : (
            <Typography>No results found</Typography>
          )}
        </ul>
      </Box>
    </div>
  );
};

export default SearchForm;

