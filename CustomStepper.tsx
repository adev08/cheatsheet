import React, { useState } from "react";
import {
  Box,
  Button,
  Stepper,
  Step,
  StepLabel,
  Typography,
  styled,
} from "@mui/material";

// Step labels
const steps = ["Step One", "Step Two", "Final Step"];

// Styled components for custom styling
const CustomStepper = styled(Stepper)(({ theme }) => ({
  padding: theme.spacing(3),
  backgroundColor: theme.palette.background.paper,
  borderRadius: theme.shape.borderRadius,
  boxShadow: theme.shadows[3],
}));

const CustomStepLabel = styled(StepLabel)(({ theme, active }) => ({
  "& .MuiStepIcon-root": {
    color: active ? theme.palette.primary.main : theme.palette.grey[400],
  },
  "& .MuiStepIcon-text": {
    fill: active ? theme.palette.common.white : theme.palette.grey[700],
  },
}));

const CustomStepContent = styled(Box)(({ theme }) => ({
  padding: theme.spacing(3),
  border: `1px solid ${theme.palette.divider}`,
  borderRadius: theme.shape.borderRadius,
  backgroundColor: theme.palette.background.default,
  marginBottom: theme.spacing(2),
}));

const CustomButton = styled(Button)(({ theme }) => ({
  borderRadius: theme.shape.borderRadius,
  textTransform: "capitalize",
  "&:hover": {
    boxShadow: theme.shadows[2],
  },
}));

const CustomStepperComponent = () => {
  const [activeStep, setActiveStep] = useState(0);

  const handleNext = () => {
    setActiveStep((prevStep) => prevStep + 1);
  };

  const handleBack = () => {
    setActiveStep((prevStep) => prevStep - 1);
  };

  const handleReset = () => {
    setActiveStep(0);
  };

  // Step content based on the active step
  const renderStepContent = (step) => {
    switch (step) {
      case 0:
        return "This is Step One content.";
      case 1:
        return "This is Step Two content.";
      case 2:
        return "You are on the final step!";
      default:
        return "Unknown step.";
    }
  };

  return (
    <Box sx={{ width: "60%", margin: "auto", marginTop: 5 }}>
      <CustomStepper activeStep={activeStep}>
        {steps.map((label, index) => (
          <Step key={label}>
            <CustomStepLabel active={index === activeStep}>
              {label}
            </CustomStepLabel>
          </Step>
        ))}
      </CustomStepper>

      <CustomStepContent>
        <Typography>{renderStepContent(activeStep)}</Typography>
      </CustomStepContent>

      <Box sx={{ display: "flex", justifyContent: "space-between" }}>
        <CustomButton
          variant="outlined"
          onClick={handleBack}
          disabled={activeStep === 0}
        >
          Back
        </CustomButton>
        {activeStep === steps.length - 1 ? (
          <CustomButton variant="contained" color="primary" onClick={handleReset}>
            Reset
          </CustomButton>
        ) : (
          <CustomButton variant="contained" color="primary" onClick={handleNext}>
            Next
          </CustomButton>
        )}
      </Box>
    </Box>
  );
};

export default CustomStepperComponent;
