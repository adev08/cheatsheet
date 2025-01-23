import React, { useState } from "react";
import {
  Box,
  Button,
  Step,
  StepLabel,
  Stepper,
  Typography,
  TextField,
} from "@mui/material";

// Define step labels
const steps = ["Personal Information", "Contact Details", "Review & Submit"];

// Step 1 Form
const PersonalInformationForm = ({ data, handleChange }) => (
  <Box>
    <TextField
      label="First Name"
      name="firstName"
      value={data.firstName}
      onChange={handleChange}
      fullWidth
      margin="normal"
    />
    <TextField
      label="Last Name"
      name="lastName"
      value={data.lastName}
      onChange={handleChange}
      fullWidth
      margin="normal"
    />
  </Box>
);

// Step 2 Form
const ContactDetailsForm = ({ data, handleChange }) => (
  <Box>
    <TextField
      label="Email"
      name="email"
      value={data.email}
      onChange={handleChange}
      fullWidth
      margin="normal"
    />
    <TextField
      label="Phone Number"
      name="phone"
      value={data.phone}
      onChange={handleChange}
      fullWidth
      margin="normal"
    />
  </Box>
);

// Step 3 Form
const ReviewForm = ({ data }) => (
  <Box>
    <Typography variant="h6">Review Your Details</Typography>
    <Typography>Name: {`${data.firstName} ${data.lastName}`}</Typography>
    <Typography>Email: {data.email}</Typography>
    <Typography>Phone: {data.phone}</Typography>
  </Box>
);

const StepperForm = () => {
  const [activeStep, setActiveStep] = useState(0);
  const [formData, setFormData] = useState({
    firstName: "",
    lastName: "",
    email: "",
    phone: "",
  });

  const handleNext = () => {
    setActiveStep((prevStep) => prevStep + 1);
  };

  const handleBack = () => {
    setActiveStep((prevStep) => prevStep - 1);
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
  };

  const handleSubmit = () => {
    // Handle form submission logic here
    console.log("Form Submitted:", formData);
    setActiveStep(steps.length); // Move to a completion screen
  };

  const renderStepContent = (step) => {
    switch (step) {
      case 0:
        return <PersonalInformationForm data={formData} handleChange={handleChange} />;
      case 1:
        return <ContactDetailsForm data={formData} handleChange={handleChange} />;
      case 2:
        return <ReviewForm data={formData} />;
      default:
        return <Typography>Unknown Step</Typography>;
    }
  };

  return (
    <Box sx={{ width: "50%", margin: "auto", marginTop: 4 }}>
      <Stepper activeStep={activeStep}>
        {steps.map((label) => (
          <Step key={label}>
            <StepLabel>{label}</StepLabel>
          </Step>
        ))}
      </Stepper>

      <Box sx={{ marginTop: 4 }}>
        {activeStep === steps.length ? (
          <Typography variant="h6">Thank you! Your information has been submitted.</Typography>
        ) : (
          <>
            {renderStepContent(activeStep)}
            <Box sx={{ display: "flex", justifyContent: "space-between", marginTop: 4 }}>
              <Button
                disabled={activeStep === 0}
                onClick={handleBack}
                variant="outlined"
              >
                Back
              </Button>
              {activeStep === steps.length - 1 ? (
                <Button variant="contained" onClick={handleSubmit}>
                  Submit
                </Button>
              ) : (
                <Button variant="contained" onClick={handleNext}>
                  Next
                </Button>
              )}
            </Box>
          </>
        )}
      </Box>
    </Box>
  );
};

export default StepperForm;
