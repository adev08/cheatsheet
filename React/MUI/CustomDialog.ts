import React, { useState } from "react";
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Box,
} from "@mui/material";
import { useMediaQuery, useTheme } from "@mui/material";

const CustomDialog = () => {
  const [open, setOpen] = useState(false);

  const theme = useTheme();
  const isFullScreen = useMediaQuery(theme.breakpoints.down("sm"));

  const handleOpen = () => setOpen(true);
  const handleClose = () => setOpen(false);

  return (
    <div>
      <Button variant="contained" color="primary" onClick={handleOpen}>
        Open Custom Dialog
      </Button>

      <Dialog
        open={open}
        onClose={handleClose}
        fullScreen={isFullScreen}
        aria-labelledby="custom-dialog-title"
        aria-describedby="custom-dialog-description"
        maxWidth="sm"
        fullWidth
        PaperProps={{
          style: {
            borderRadius: "10px", // Rounded corners
            padding: "20px", // Padding inside the dialog
          },
        }}
      >
        <DialogTitle
          id="custom-dialog-title"
          sx={{ textAlign: "center", fontWeight: "bold" }}
        >
          Custom Dialog Title
          <Button
            onClick={handleClose}
            sx={{ position: "absolute", right: 16, top: 16 }}
          >
            X
          </Button>
        </DialogTitle>
        <DialogContent>
          <Typography id="custom-dialog-description" sx={{ mb: 2 }}>
            This is a custom dialog description. You can add any content here,
            including forms, text, or other UI components.
          </Typography>
          <Box sx={{ display: "flex", justifyContent: "center", gap: 2 }}>
            <Button variant="outlined" color="secondary">
              Secondary Action
            </Button>
            <Button variant="outlined" color="error">
              Another Action
            </Button>
          </Box>
        </DialogContent>
        <DialogActions sx={{ justifyContent: "center" }}>
          <Button onClick={handleClose} variant="contained" color="success">
            Close
          </Button>
        </DialogActions>
      </Dialog>
    </div>
  );
};

export default CustomDialog;
