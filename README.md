# Image-Processing-Project
This MATLAB-based GUI application allows users to apply various linear and non-linear filters to images, generate different types of noise (salt &amp; pepper, Gaussian, Rayleigh, Exponential, Gamma, etc.), and visualize the results with histogram comparisons.
# MATLAB GUI for Image Filtering and Noise Simulation

This project is a graphical user interface (GUI) application built in MATLAB that enables users to load images, apply different types of filters, and simulate various noise models for testing and visualization.

## 📌 Features

- **Image Loading & Display**
  - Load and preview grayscale or RGB images
  - View original and processed images side-by-side

- **Filtering Operations**
  - **Linear Filters**: Correlation and Weighted filters
  - **Non-Linear Filters**: Min, Max, Median, Mean, and Midpoint filters
  - Customizable filter kernel via table input

- **Noise Simulation**
  - Salt & Pepper Noise (customizable PS and PP)
  - Gaussian Noise (customizable mean, standard deviation, and percentage)
  - Uniform Noise
  - Rayleigh Noise
  - Exponential Noise
  - Gamma Noise

- **Image Enhancement**
  - Histogram Equalization
  - Contrast Stretching
  - Point and Line Detection/Sharpening
  - Frequency Domain Filtering (Ideal, Butterworth, Gaussian LP/HP)

- **Histogram Visualization**
  - RGB and Grayscale histogram comparison for original vs. processed images

## 🛠️ How to Use

1. **Open MATLAB**
2. Run the `gui.m` file or load the GUI via MATLAB App Designer interface
3. Use buttons to:
   - Load an image
   - Apply a filter
   - Add noise
   - Compare histograms
   - Adjust parameters like gamma, kernel, and brightness
4. View outputs in the GUI display panels

## 🧠 Skills & Concepts Demonstrated

- GUI programming in MATLAB
- Image filtering and convolution
- Random noise models
- Image transformation techniques
- Histogram analysis and visualization

## 📂 File Structure
├── gui.m # Main GUI logic
├── gui.fig # GUI layout file (if applicable)
├── gui.html # Exported HTML documentation
└── README.md # Project overview


## 🚀 Requirements

- MATLAB R2016a or later
- Image Processing Toolbox



